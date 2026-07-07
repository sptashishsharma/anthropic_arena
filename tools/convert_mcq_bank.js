#!/usr/bin/env node
/**
 * Anthropic Arena — MCQ bank converter.
 *
 * Reads the team's Anthropic_MCQ_Bank.xlsx (S.No | Question | Option A..D,
 * correct answer marked with the bold-green cell style), classifies every
 * question into a course + topic, chunks them into levels, and writes:
 *   - assets/content/courses.json   (what the app ships)
 *   - tools/questions_master.csv    (editable master in template format)
 *
 * Usage:  node tools/convert_mcq_bank.js "path\to\Anthropic_MCQ_Bank.xlsx"
 * Needs:  npm install xlsx  (run in this folder or globally NODE_PATH)
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const XLSX = require(require.resolve('xlsx', {
  paths: [__dirname, process.cwd(), path.join(process.env.TEMP || '', 'node_modules')],
}));

const input = process.argv[2];
if (!input) {
  console.error('Usage: node convert_mcq_bank.js <xlsx path>');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// 1. Read rows + extract the bold-green "correct answer" style directly from
//    the sheet XML (SheetJS community edition doesn't expose fonts).
// ---------------------------------------------------------------------------

const wb = XLSX.readFile(input);
const sheetName = wb.SheetNames[0];
const rows = XLSX.utils.sheet_to_json(wb.Sheets[sheetName], { header: 1, defval: '' });

// Unzip the sheet XML to find, per row, which option cell uses the marked
// style. Style detection: the correct-answer font is bold + green; we find
// which cellXfs indexes point to a bold green font, then match cells.
const unzipDir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'mcq-'));
execSync(`powershell -NoProfile -Command "Copy-Item '${input}' '${unzipDir}\\f.zip'; Expand-Archive '${unzipDir}\\f.zip' '${unzipDir}\\x' -Force"`);
const stylesXml = fs.readFileSync(path.join(unzipDir, 'x', 'xl', 'styles.xml'), 'utf-8');

const fontMatches = [...stylesXml.matchAll(/<font(?:\/>|>.*?<\/font>)/gs)].map((m) => m[0]);
const greenBoldFonts = new Set(
  fontMatches
    .map((f, i) => ({ f, i }))
    .filter(({ f }) => /<b\b/.test(f) && /color rgb="00(1A5C1A|008000|00B050)"/.test(f))
    .map(({ i }) => i),
);
const xfList = [...(stylesXml.match(/<cellXfs[^>]*>(.*?)<\/cellXfs>/s)?.[1] ?? '').matchAll(/<xf [^>]*?fontId="(\d+)"[^>]*?>/g)];
const markedStyles = new Set(
  xfList.map((m, i) => ({ fontId: +m[1], i })).filter(({ fontId }) => greenBoldFonts.has(fontId)).map(({ i }) => i),
);

const sheetXml = fs.readFileSync(path.join(unzipDir, 'x', 'xl', 'worksheets', 'sheet1.xml'), 'utf-8');
const cellStyles = {}; // row -> col letter -> style id
for (const [, col, row, s] of sheetXml.matchAll(/<c r="([A-Z]+)(\d+)"(?:[^>]*?s="(\d+)")?[^>]*?(?:\/>|>.*?<\/c>)/gs)) {
  (cellStyles[row] ??= {})[col] = +(s ?? 0);
}

const OPTION_COLS = { C: 0, D: 1, E: 2, F: 3 };
const LETTERS = ['A', 'B', 'C', 'D'];

// Manual decisions for rows the styling can't answer (reviewed by hand):
//  - S.No 96 is corrupt in the source (option D belongs to another question) -> skipped
//  - S.No 127 has no marking; correct answer is A
//  - S.No 291/294 are "select all that apply" -> rephrased to single-answer NOT-questions
const OVERRIDES = {
  96: { skip: true, note: 'corrupt row — option D is a fragment of another question' },
  127: { correct: 0 },
  291: {
    question: 'Which of the following statements about AI is NOT true?',
    correct: 0,
    note: 'rephrased from "select all that apply"',
  },
  294: {
    question: 'Which of the following does NOT help you build confidence when using AI for data analysis?',
    correct: 3,
    note: 'rephrased from "select all that apply"',
  },
};

// ---------------------------------------------------------------------------
// 2. Topic classification (first matching rule wins).
// ---------------------------------------------------------------------------

const TOPIC_RULES = [
  ['AI Fluency', /AI Fluency|4Ds|\bDelegation\b|\bDiscernment\b|\bDiligence\b|calibrated trust|this course/i],
  ['Responsible AI at Work', /use policy|sensitive data|job application|resume|cover letter|stays human|accountab|privacy|confidential/i],
  ['MCP', /\bMCP\b/],
  ['Claude Code', /Claude Code/i],
  ['Skills & Projects', /\bskills?\b.*\b(plugins?|projects?)\b|\b(plugins?|projects?)\b.*\bskills?\b|\bconnectors?\b|\bplugins?\b|\bprojects?\b.*knowledge|SKILL\.md/i],
  ['Prompt Caching', /cach/i],
  ['Evaluation & Testing', /grader|\beval(uation|s)?\b|test cases?|measure how well|A\/B test|benchmark/i],
  ['RAG & Search', /semantic search|BM25|embedding|chunk|retriev|\bRAG\b|rerank|reciprocal rank/i],
  ['Tool Use', /\btools?\b.*(function|definition|result|call|schema|choice|built-in|custom|batch)|tool_|give Claude the ability/i],
  ['Claude API', /messages\.create|API key|\bAPI\b|streaming|server-sent|\bSDK\b|max_tokens|stop_reason|rate limit|status code|temperature|top_p|system prompt.*api/i],
  ['Vision & Files', /\bimage\b|\bvision\b|\bPDF\b|video\.mp4|multimodal/i],
  ['Safety & Alignment', /Constitutional AI|hallucinat|fine-tun|fingerprint|jailbreak|safety|alignment|red.?team/i],
  ['Prompting', /prompt|XML tag|few-shot|role|prefill|chain of thought|instruction|persona|rewrite/i],
  ['Claude Basics', /.*/],
];

const COURSES = [
  { id: 'claude-foundations', title: 'Claude Foundations', tagline: 'Models, tokens & how Claude thinks', color: '#F5A623', topics: ['Claude Basics', 'Safety & Alignment', 'Vision & Files'] },
  { id: 'prompting-mastery', title: 'Prompting Mastery', tagline: 'Write prompts that actually work', color: '#4FC3F7', topics: ['Prompting', 'Evaluation & Testing'] },
  { id: 'ai-fluency', title: 'AI Fluency at Work', tagline: 'Use AI responsibly and effectively', color: '#81C784', topics: ['AI Fluency', 'Responsible AI at Work'] },
  { id: 'claude-platform', title: 'Claude Platform', tagline: 'Skills, projects, connectors & Claude Code', color: '#BA68C8', topics: ['Skills & Projects', 'Claude Code'] },
  { id: 'claude-api', title: 'Building with the API', tagline: 'From first call to production', color: '#FF8A65', topics: ['Claude API', 'Prompt Caching'] },
  { id: 'tools-mcp-rag', title: 'Tools, MCP & RAG', tagline: 'Agents, integrations & retrieval', color: '#4DB6AC', topics: ['Tool Use', 'MCP', 'RAG & Search'] },
];

const QUESTIONS_PER_LEVEL = 7;

// ---------------------------------------------------------------------------
// 3. Build questions.
// ---------------------------------------------------------------------------

const skipped = [];
const questions = [];

for (let r = 2; r < rows.length + 1; r++) {
  const row = rows[r - 1];
  if (!row || row.length < 6 || !row[1]) continue;
  const sno = +row[0];
  const override = OVERRIDES[sno] ?? {};
  if (override.skip) {
    skipped.push({ sno, reason: override.note });
    continue;
  }

  let correct = override.correct;
  if (correct === undefined) {
    const marked = Object.keys(OPTION_COLS).filter((c) => markedStyles.has(cellStyles[r]?.[c]));
    if (marked.length !== 1) {
      skipped.push({ sno, reason: `expected exactly one marked option, found ${marked.length}` });
      continue;
    }
    correct = OPTION_COLS[marked[0]];
  }

  const text = `${row[1]} ${row[2]} ${row[3]} ${row[4]} ${row[5]}`;
  const topic = TOPIC_RULES.find(([, re]) => re.test(text))[0];

  questions.push({
    id: `sno-${sno}`,
    topic,
    question: override.question ?? String(row[1]).trim(),
    options: [row[2], row[3], row[4], row[5]].map((o) => String(o).trim()),
    correctIndex: correct,
    explanation: '',
    note: override.note,
  });
}

// ---------------------------------------------------------------------------
// 4. Chunk into courses/levels.
// ---------------------------------------------------------------------------

const out = { version: 2, courses: [] };
const csvRows = [
  'course_id,course_title,course_tagline,course_description,course_order,course_color,level_id,level_title,level_order,level_topic,pass_mark,xp_per_correct,question_id,topic,question,option_a,option_b,option_c,option_d,correct,explanation,resource_title,resource_url',
];
const csvEscape = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

let courseOrder = 0;
for (const spec of COURSES) {
  courseOrder++;
  const pool = spec.topics.flatMap((t) => questions.filter((q) => q.topic === t));
  if (!pool.length) continue;

  const levels = [];
  for (let i = 0; i < pool.length; i += QUESTIONS_PER_LEVEL) {
    let chunk = pool.slice(i, i + QUESTIONS_PER_LEVEL);
    // Merge a tiny tail into the previous level rather than shipping a 1-2 question level.
    if (chunk.length < 4 && levels.length) {
      levels[levels.length - 1].questions.push(...chunk);
      break;
    }
    levels.push({ questions: chunk });
  }

  const course = {
    id: spec.id,
    title: spec.title,
    tagline: spec.tagline,
    description: `${spec.tagline}. ${pool.length} questions across ${levels.length} levels.`,
    order: courseOrder,
    color: spec.color,
    levels: levels.map((lvl, i) => {
      // Name each level after its dominant topic.
      const counts = {};
      for (const q of lvl.questions) counts[q.topic] = (counts[q.topic] ?? 0) + 1;
      const dominant = Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
      const priorSame = levels.slice(0, i).filter((p) => p.title?.startsWith(dominant)).length;
      const title = priorSame ? `${dominant} ${priorSame + 1}` : dominant;
      const level = {
        id: `${spec.id}-l${i + 1}`,
        title,
        order: i + 1,
        topic: dominant,
        passMark: 70,
        xpPerCorrect: 10,
        questions: lvl.questions.map(({ note, ...q }) => q),
      };
      lvl.title = title;
      for (const q of lvl.questions) {
        csvRows.push([
          spec.id, spec.title, spec.tagline, '', courseOrder, spec.color,
          level.id, title, i + 1, dominant, 70, 10,
          q.id, q.topic, q.question, ...q.options, LETTERS[q.correctIndex], q.explanation, '', '',
        ].map(csvEscape).join(','));
      }
      return level;
    }),
  };
  out.courses.push(course);
}

// ---------------------------------------------------------------------------
// 5. Write outputs + report.
// ---------------------------------------------------------------------------

const root = path.join(__dirname, '..');
fs.writeFileSync(path.join(root, 'assets', 'content', 'courses.json'), JSON.stringify(out, null, 2));
fs.writeFileSync(path.join(root, 'tools', 'questions_master.csv'), csvRows.join('\n'));

let total = 0;
for (const c of out.courses) {
  const n = c.levels.reduce((s, l) => s + l.questions.length, 0);
  total += n;
  console.log(`${c.title.padEnd(24)} ${String(c.levels.length).padStart(2)} levels  ${String(n).padStart(3)} questions`);
}
console.log(`TOTAL ${total} questions in ${out.courses.length} courses`);
if (skipped.length) console.log('SKIPPED:', JSON.stringify(skipped));
