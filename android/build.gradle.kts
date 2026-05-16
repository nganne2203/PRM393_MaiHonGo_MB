import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun Project.resolveAndroidNamespace(): String {
    val manifestFile = projectDir.resolve("src/main/AndroidManifest.xml")
    if (manifestFile.exists()) {
        val manifestText = manifestFile.readText()
        val packageMatch = Regex("""package\s*=\s*\"([^\"]+)\"""")
            .find(manifestText)
            ?.groupValues
            ?.getOrNull(1)
        if (!packageMatch.isNullOrBlank()) {
            return packageMatch
        }
    }

    val sanitizedName = name.replace(Regex("[^A-Za-z0-9_]"), "_")
    return "dev.flutter.$sanitizedName"
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            if (namespace.isNullOrBlank()) {
                namespace = project.resolveAndroidNamespace()
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
