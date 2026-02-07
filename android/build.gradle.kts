allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            val safeName = name.replace('-', '_')
            extensions.findByName("android")?.let { ext ->
                val namespaceProperty = ext.javaClass.getMethod("getNamespace")
                val current = namespaceProperty.invoke(ext) as String?
                if (current.isNullOrBlank()) {
                    val setNamespace = ext.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(ext, "com.github.flutter.$safeName")
                }
            }
        }
    }
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
