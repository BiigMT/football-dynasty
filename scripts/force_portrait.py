from pathlib import Path
import sys
import xml.etree.ElementTree as ET

root = Path(sys.argv[1])
manifest = root / "android/app/src/main/AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit(f"Android manifest not found: {manifest}")

android_ns = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", android_ns)
tree = ET.parse(manifest)
app = tree.getroot()
launcher = None

for activity in app.iter("activity"):
    for intent_filter in activity.findall("intent-filter"):
        actions = [node.get(f"{{{android_ns}}}name") for node in intent_filter.findall("action")]
        categories = [node.get(f"{{{android_ns}}}name") for node in intent_filter.findall("category")]
        if "android.intent.action.MAIN" in actions and "android.intent.category.LAUNCHER" in categories:
            launcher = activity
            break
    if launcher is not None:
        break

if launcher is None:
    raise SystemExit("Could not find the MAIN/LAUNCHER activity in AndroidManifest.xml")

launcher.set(f"{{{android_ns}}}screenOrientation", "portrait")
tree.write(manifest, encoding="utf-8", xml_declaration=True)

verified = ET.parse(manifest).getroot()
for activity in verified.iter("activity"):
    for intent_filter in activity.findall("intent-filter"):
        actions = [node.get(f"{{{android_ns}}}name") for node in intent_filter.findall("action")]
        categories = [node.get(f"{{{android_ns}}}name") for node in intent_filter.findall("category")]
        if "android.intent.action.MAIN" in actions and "android.intent.category.LAUNCHER" in categories:
            value = activity.get(f"{{{android_ns}}}screenOrientation")
            if value != "portrait":
                raise SystemExit("Portrait orientation verification failed")
            print("Verified: launcher activity is locked to portrait.")
            raise SystemExit(0)

raise SystemExit("Portrait orientation verification failed after writing manifest.")
