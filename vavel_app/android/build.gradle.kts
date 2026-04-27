import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
        // walletconnect_pay → com.github.reown-com.yttrium:yttrium-wcpay (Reown / WalletConnect Pay)
        maven { url = uri("https://jitpack.io") }
        // Huawei Mobile Services (Push Kit, hms-availability, etc.)
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
}

// Align Java language level for all Android library subprojects (stops JDK 8 obsolete warnings from plugins).
subprojects {
    afterEvaluate {
        extensions.findByType<BaseExtension>()?.compileOptions?.apply {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
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
