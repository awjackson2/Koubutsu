#!/usr/bin/env python3
"""Generates Koubutsu.xcodeproj/project.pbxproj deterministically.

The project uses file-system-synchronized groups (Xcode 16+, objectVersion 77), so source files are
discovered from the App/ and AppTests/ folders and never need to be listed here. Re-run this script only
when targets, build settings, or package links change:

    python3 Tools/gen_xcodeproj.py
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Koubutsu.xcodeproj", "project.pbxproj")

DEPLOYMENT_TARGET = "26.0"
BUNDLE_ID = "com.awjackson2.Koubutsu"


def oid(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


I = {k: oid(k) for k in [
    "project", "mainGroup", "productsGroup", "appGroup", "testsGroup",
    "appProduct", "testsProduct",
    "appTarget", "testsTarget",
    "appSources", "appFrameworks", "appResources",
    "testsSources", "testsFrameworks", "testsResources",
    "coreBuildFile", "corePackageRef", "coreProductDep",
    "testsDependency", "testsProxy",
    "projConfigList", "projDebug", "projRelease",
    "appConfigList", "appDebug", "appRelease",
    "testsConfigList", "testsDebug", "testsRelease",
]}


def settings(d: dict) -> str:
    lines = []
    for k in sorted(d):
        v = d[k]
        if isinstance(v, list):
            inner = "".join(f"\n\t\t\t\t\t\"{x}\"," for x in v)
            lines.append(f"\t\t\t\t{k} = ({inner}\n\t\t\t\t);")
        else:
            s = str(v)
            if s == "" or any(c in s for c in " $()=-+/;,\"<>*@") and not s.replace(".", "").isdigit():
                s = '"' + s.replace('"', '\\"') + '"'
            lines.append(f"\t\t\t\t{k} = {s};")
    return "\n".join(lines)


COMMON_PROJECT = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "2",
}
PROJ_DEBUG = dict(COMMON_PROJECT, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
})
PROJ_RELEASE = dict(COMMON_PROJECT, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
})

APP = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "Koubutsu",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.utilities",
    "INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace": "YES",
    "INFOPLIST_KEY_UIFileSharingEnabled": "YES",
    "INFOPLIST_KEY_NSCameraUsageDescription":
        "Koubutsu reads video from an external USB capture device to display and translate game text.",
    "INFOPLIST_KEY_NSMicrophoneUsageDescription":
        "Koubutsu reads audio from an external USB capture device to play game audio.",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UIRequiresFullScreen": "YES",
    "INFOPLIST_KEY_UIStatusBarHidden": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad":
        "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight "
        "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "0.1",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SUPPORTS_MACCATALYST": "NO",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "2",
}
TESTS = {
    "BUNDLE_LOADER": "$(TEST_HOST)",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "0.1",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID + "Tests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TARGETED_DEVICE_FAMILY": "2",
    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Koubutsu.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Koubutsu",
}


def config(key, name, d):
    return (f"\t\t{I[key]} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n"
            f"\t\t\tbuildSettings = {{\n{settings(d)}\n\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n")


def phase(key, isa, files=""):
    return (f"\t\t{I[key]} = {{\n\t\t\tisa = {isa};\n\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tfiles = ({files}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")


def config_list(key, debug, release, comment):
    return (f"\t\t{I[key]} /* Build configuration list for {comment} */ = {{\n"
            f"\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n"
            f"\t\t\t\t{I[debug]} /* Debug */,\n\t\t\t\t{I[release]} /* Release */,\n\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n")


out = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 77;
	objects = {{

/* Begin PBXBuildFile section */
		{I['coreBuildFile']} /* KoubutsuCore in Frameworks */ = {{isa = PBXBuildFile; productRef = {I['coreProductDep']} /* KoubutsuCore */; }};
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{I['testsProxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {I['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {I['appTarget']};
			remoteInfo = Koubutsu;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		{I['appProduct']} /* Koubutsu.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Koubutsu.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{I['testsProduct']} /* KoubutsuTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = KoubutsuTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		{I['appGroup']} /* App */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = App;
			sourceTree = "<group>";
		}};
		{I['testsGroup']} /* AppTests */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = AppTests;
			sourceTree = "<group>";
		}};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
{phase('appFrameworks', 'PBXFrameworksBuildPhase', chr(10) + chr(9)*4 + I['coreBuildFile'] + ' /* KoubutsuCore in Frameworks */,')}{phase('testsFrameworks', 'PBXFrameworksBuildPhase')}/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{I['mainGroup']} = {{
			isa = PBXGroup;
			children = (
				{I['appGroup']} /* App */,
				{I['testsGroup']} /* AppTests */,
				{I['productsGroup']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{I['productsGroup']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{I['appProduct']} /* Koubutsu.app */,
				{I['testsProduct']} /* KoubutsuTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{I['appTarget']} /* Koubutsu */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {I['appConfigList']} /* Build configuration list for PBXNativeTarget "Koubutsu" */;
			buildPhases = (
				{I['appSources']} /* Sources */,
				{I['appFrameworks']} /* Frameworks */,
				{I['appResources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{I['appGroup']} /* App */,
			);
			name = Koubutsu;
			packageProductDependencies = (
				{I['coreProductDep']} /* KoubutsuCore */,
			);
			productName = Koubutsu;
			productReference = {I['appProduct']} /* Koubutsu.app */;
			productType = "com.apple.product-type.application";
		}};
		{I['testsTarget']} /* KoubutsuTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {I['testsConfigList']} /* Build configuration list for PBXNativeTarget "KoubutsuTests" */;
			buildPhases = (
				{I['testsSources']} /* Sources */,
				{I['testsFrameworks']} /* Frameworks */,
				{I['testsResources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{I['testsDependency']} /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				{I['testsGroup']} /* AppTests */,
			);
			name = KoubutsuTests;
			packageProductDependencies = (
			);
			productName = KoubutsuTests;
			productReference = {I['testsProduct']} /* KoubutsuTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{I['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {{
					{I['appTarget']} = {{
						CreatedOnToolsVersion = 26.0;
					}};
					{I['testsTarget']} = {{
						CreatedOnToolsVersion = 26.0;
						TestTargetID = {I['appTarget']};
					}};
				}};
			}};
			buildConfigurationList = {I['projConfigList']} /* Build configuration list for PBXProject "Koubutsu" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
				ja,
			);
			mainGroup = {I['mainGroup']};
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				{I['corePackageRef']} /* XCLocalSwiftPackageReference "Packages/KoubutsuCore" */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = {I['productsGroup']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{I['appTarget']} /* Koubutsu */,
				{I['testsTarget']} /* KoubutsuTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
{phase('appResources', 'PBXResourcesBuildPhase')}{phase('testsResources', 'PBXResourcesBuildPhase')}/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{phase('appSources', 'PBXSourcesBuildPhase')}{phase('testsSources', 'PBXSourcesBuildPhase')}/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{I['testsDependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {I['appTarget']} /* Koubutsu */;
			targetProxy = {I['testsProxy']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
{config('projDebug', 'Debug', PROJ_DEBUG)}{config('projRelease', 'Release', PROJ_RELEASE)}{config('appDebug', 'Debug', APP)}{config('appRelease', 'Release', APP)}{config('testsDebug', 'Debug', TESTS)}{config('testsRelease', 'Release', TESTS)}/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{config_list('projConfigList', 'projDebug', 'projRelease', 'PBXProject "Koubutsu"')}{config_list('appConfigList', 'appDebug', 'appRelease', 'PBXNativeTarget "Koubutsu"')}{config_list('testsConfigList', 'testsDebug', 'testsRelease', 'PBXNativeTarget "KoubutsuTests"')}/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		{I['corePackageRef']} /* XCLocalSwiftPackageReference "Packages/KoubutsuCore" */ = {{
			isa = XCLocalSwiftPackageReference;
			relativePath = Packages/KoubutsuCore;
		}};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		{I['coreProductDep']} /* KoubutsuCore */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {I['corePackageRef']} /* XCLocalSwiftPackageReference "Packages/KoubutsuCore" */;
			productName = KoubutsuCore;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = {I['project']} /* Project object */;
}}
"""

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    f.write(out)

SCHEME = os.path.join(ROOT, "Koubutsu.xcodeproj", "xcshareddata", "xcschemes", "Koubutsu.xcscheme")
os.makedirs(os.path.dirname(SCHEME), exist_ok=True)
ref_app = (f'BuildableIdentifier = "primary" BlueprintIdentifier = "{I["appTarget"]}" '
           f'BuildableName = "Koubutsu.app" BlueprintName = "Koubutsu" '
           f'ReferencedContainer = "container:Koubutsu.xcodeproj"')
ref_tests = (f'BuildableIdentifier = "primary" BlueprintIdentifier = "{I["testsTarget"]}" '
             f'BuildableName = "KoubutsuTests.xctest" BlueprintName = "KoubutsuTests" '
             f'ReferencedContainer = "container:Koubutsu.xcodeproj"')
with open(SCHEME, "w") as f:
    f.write(f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference {ref_app}>
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO" parallelizable = "NO">
            <BuildableReference {ref_tests}>
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference {ref_app}>
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference {ref_app}>
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
""")
print("wrote", OUT)
print("wrote", SCHEME)
