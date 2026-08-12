import QtQuick
import qs.Data as Dat

Image {
  // when set, resolves this output's wallpaper override (falling back to
  // the global wallSrc); leave empty to always use the global wallSrc
  property string outputName: ""

  antialiasing: true
  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  layer.enabled: true
  retainWhileLoading: true
  smooth: true
  // Qt.resolvedUrl() turns a bare filesystem path (what Config.qml
  // actually stores - no file:// scheme) into a proper file:// URL.
  // QtQuick's Image.source *usually* tolerates a bare path, but not
  // reliably across every QtQuick Image backend/version - and if it
  // silently no-ops instead of erroring, onStatusChanged's Image.Error
  // branch below never even fires, so this was never actually ruled out
  // just because no error was logged. Wrapping it here costs nothing on
  // the paths where a bare string already worked, and fixes it on the
  // ones where it didn't.
  source: Dat.Config.wallpaperFor(outputName) ? Qt.resolvedUrl(Dat.Config.wallpaperFor(outputName)) : ""

  onStatusChanged: {
    if (this.status == Image.Error) {
      console.log("[ERROR] Wallpaper source invalid: " + source);
      console.log("[INFO] Please disable set wallpaper if not required");
    }
  }
}
