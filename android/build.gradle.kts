buildscript {
    ext.kotlin_version = '1.8.22' // Downgraded for compatibility

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2' // Downgraded from 8.3.0
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
    project.evaluationDependsOn(':app')
    project.configurations.all {
        resolutionStrategy.eachDependency { details ->
            // Optional: add resolution strategy here if needed
        }
    }
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
