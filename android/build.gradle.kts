allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build outside the project tree: this project lives in a OneDrive-synced
// folder, and OneDrive's sync scanner locks Gradle's intermediate files
// mid-build (random AccessDeniedException failures). C:\dev is not synced.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("C:/dev/builds/anthropic_arena")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
