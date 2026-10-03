import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

try {
    val gitPath = "C:\\Program Files\\Git\\cmd"
    val peClass = Class.forName("java.lang.ProcessEnvironment")
    val envField = peClass.getDeclaredField("theEnvironment")
    envField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val env = envField.get(null) as MutableMap<String, String>
    val pathKey = env.keys.firstOrNull { it.equals("PATH", ignoreCase = true) } ?: "Path"
    val currentPath = env[pathKey] ?: ""
    if (!currentPath.contains(gitPath, ignoreCase = true)) {
        env[pathKey] = "$gitPath;$currentPath"
    }

    val ciEnvField = peClass.getDeclaredField("theCaseInsensitiveEnvironment")
    ciEnvField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val ciEnv = ciEnvField.get(null) as MutableMap<String, String>
    ciEnv[pathKey] = "$gitPath;$currentPath"
} catch (_: Throwable) {
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            val getCompileOptions = androidExt.javaClass.getMethod("getCompileOptions")
            val compileOptions = getCompileOptions.invoke(androidExt)
            val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
            val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
            setSource.invoke(compileOptions, JavaVersion.VERSION_17)
            setTarget.invoke(compileOptions, JavaVersion.VERSION_17)
        }
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
