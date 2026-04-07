buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Esta linha é essencial para o Workmanager e outros plugins Kotlin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                compileSdkVersion(36) 
                
                if (namespace == null) {
                    namespace = project.group.toString()
                }
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