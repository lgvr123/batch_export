import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2 // FileDialogs
import QtQuick.Window 2.3
import Qt.labs.folderlistmodel 2.2
import Qt.labs.settings 1.0
import QtQml 2.8
import MuseScore 3.0
import FileIO 3.0
import "batch_convert"

//TODO : translations
//TODO : Result dialog box

MuseScore {
    menuPath: "Plugins." + qsTr("Batch Convert") // this doesn't work, why?
    version: "3.6"
    requiresScore: false
    description: qsTr("This plugin converts multiple files from various formats"
                      + " into various formats")
    pluginType: "dialog"

    MessageDialog {
        id: versionError
        visible: false
        title: qsTr("Unsupported MuseScore Version")
        text: qsTr("This plugin needs MuseScore 3")
        onAccepted: {
            batchConvert.parent.Window.window.close();
        }
    }

    Settings {
        id: mscorePathsSettings
        category: "application/paths"
        property var myScores
    }
    property var exportToPath
    property bool convert: false // Do the conversion, or preview only
    
    SystemPalette { id: sysActivePalette; colorGroup: SystemPalette.Active }
    SystemPalette { id: sysDisabledPalette; colorGroup: SystemPalette.Disabled }

    onRun: {
        // check MuseScore version
        if (mscoreMajorVersion < 3) { // we should really never get here, but fail at the imports above already
            batchConvert.visible = false
            versionError.open()
        }
        else
            batchConvert.visible = true // needed for unknown reasons
        if (settings.iPath==="")
            settings.iPath=mscorePathsSettings.myScores;
        if (settings.ePath==="")
            settings.ePath=settings.iPath;
    }

    //Window {
    id: batchConvert

    // `width` and `height` allegedly are not valid property names, works regardless and seems needed?!
    width: mainRow.childrenRect.width + 40
    height: mainRow.childrenRect.height + 20

    // Mutally exclusive in/out formats, doesn't work properly
    ButtonGroup  { id: mscz }
    ButtonGroup  { id: mscx }
    ButtonGroup  { id: xml }
    ButtonGroup  { id: mxl }
    ButtonGroup  { id: musicxml }
    ButtonGroup  { id: mid }
    ButtonGroup  { id: midi }
    ButtonGroup  { id: pdf }

    GridLayout {
        id: mainRow
        columnSpacing: 2
        columns: 3
        
        GroupBox {
            id: inFormats
            title: " " + qsTr("Input Formats") + " "
            Layout.margins: 10
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            Layout.column: 1
            Layout.row: 1
            Layout.rowSpan: 2
            //flat: true // no effect?!
            //checkable: true // no effect?!
            property var extensions: new Array
            Column {
                spacing: 0
                SmallCheckBox {
                    id: inMscz
                    text: "*.mscz"
                    checked: true
                    //ButtonGroup.group: mscz
                    onClicked: {
                        if (checked && outMscz.checked)
                            outMscz.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore Files")
                }
                SmallCheckBox {
                    id: inMscx
                    text: "*.mscx"
                    //ButtonGroup.group: mscx
                    onClicked: {
                        if (checked && outMscx.checked)
                            outMscx.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore Files")
                }
                SmallCheckBox {
                    id: inMsc
                    text: "*.msc"
                    enabled: (mscoreMajorVersion < 2) ? true : false // MuseScore < 2.0
                    visible: enabled // hide if not enabled
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore Files")
                }
                SmallCheckBox {
                    id: inXml
                    text: "*.xml"
                    //ButtonGroup.group: xml
                    onClicked: {
                        if (checked && outXml.checked)
                            outXml.checked = !checked
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MusicXML Files")
                }
                SmallCheckBox {
                    id: inMusicXml
                    text: "*.musicxml"
                    //ButtonGroup.group: musicxml
                    enabled: (mscoreMajorVersion >= 3 || (mscoreMajorVersion == 2 && mscoreMinorVersion > 1)) ? true : false // MuseScore > 2.1
                    visible: enabled // hide if not enabled
                    onClicked: {
                        if (checked && outMusicXml.checked)
                            outMusicXml.checked = !checked
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MusicXML Files")
                }
                SmallCheckBox {
                    id: inMxl
                    text: "*.mxl"
                    //ButtonGroup.group: mxl
                    onClicked: {
                        if (checked && outMxl.checked)
                            outMxl.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MusicXML Files")
                }
                SmallCheckBox {
                    id: inMid
                    text: "*.mid"
                    //ButtonGroup.group: mid
                    onClicked: {
                        if (checked && outMid.checked)
                            outMid.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MIDI Files")
                }
                SmallCheckBox {
                    id: inMidi
                    text: "*.midi"
                    //ButtonGroup.group: midi
                    onClicked: {
                        if (checked && outMidi.checked)
                            outMidi.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MIDI Files")
                }
                SmallCheckBox {
                    id: inKar
                    text: "*.kar"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MIDI Files")
                }
                SmallCheckBox {
                    id: inMd
                    text: "*.md"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseData Files")
                }
                SmallCheckBox {
                    id: inPdf
                    text: "*.pdf"
                    enabled: false // needs OMR, MuseScore > 2.0 or > 3.5?
                    visible: enabled // hide if not enabled
                    //ButtonGroup.group: pdf
                    onClicked: {
                        if (checked && outPdf.checked)
                            outPdf.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Optical Music Recognition")
                }
                SmallCheckBox {
                    id: inCap
                    text: "*.cap"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Capella Files")
                }
                SmallCheckBox {
                    id: inCapx
                    text: "*.capx"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Capella Files")
                }
                SmallCheckBox {
                    id: inMgu
                    text: "*.mgu"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "BB Files (experimental)")
                }
                SmallCheckBox {
                    id: inSgu
                    text: "*.sgu"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "BB Files (experimental)")
                }
                SmallCheckBox {
                    id: inOve
                    text: "*.ove"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Overture / Score Writer Files (experimental)")
                }
                SmallCheckBox {
                    id: inScw
                    text: "*.scw"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Overture / Score Writer Files (experimental)")
                }
                SmallCheckBox {
                    id: inBmw
                    enabled: (mscoreMajorVersion >= 4 || (mscoreMajorVersion == 3 && mscoreMinorVersion >= 5)) ? true : false // MuseScore 3.5
                    visible: enabled // hide if not enabled
                    text: "*.bmw"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Bagpipe Music Writer Files (experimental)")
                }
                SmallCheckBox {
                    id: inBww
                    text: "*.bww"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Bagpipe Music Writer Files (experimental)")
                }
                SmallCheckBox {
                    id: inGtp
                    text: "*.gtp"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inGp3
                    text: "*.gp3"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inGp4
                    text: "*.gp4"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inGp5
                    text: "*.gp5"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inGpx
                    text: "*.gpx"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inGp
                    enabled: (mscoreMajorVersion >= 4 || (mscoreMajorVersion == 3 && mscoreMinorVersion >= 5)) ? true : false // MuseScore 3.5
                    visible: enabled // hide if not enabled
                    text: "*.gp"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Guitar Pro")
                }
                SmallCheckBox {
                    id: inPtb
                    enabled: (mscoreMajorVersion >= 3) ? true : false // MuseScore 3
                    visible: enabled // hide if not enabled
                    text: "*.ptb"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Power Tab Editor Files (experimental)")
                }
                SmallCheckBox {
                    id: inMsczComma
                    enabled: (mscoreMajorVersion >= 4 || (mscoreMajorVersion == 3 && mscoreMinorVersion >= 5)) ? true : false // MuseScore 3.5
                    visible: enabled // hide if not enabled
                    text: "*.mscz,"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore Backup Files")
                }
                SmallCheckBox {
                    id: inMscxComma
                    enabled: (mscoreMajorVersion >= 4 || (mscoreMajorVersion == 3 && mscoreMinorVersion >= 5)) ? true : false // MuseScore 3.5
                    visible: enabled // hide if not enabled
                    text: "*.mscx,"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore Backup Files")
                }
            } // Column
        } // inFormats

        Label {
            Layout.column: 2
            Layout.row: 1
            Layout.fillHeight: false
            text: " ===> "
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }
        GroupBox {
            id: outFormats
            Layout.column: 3
            Layout.row: 1
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            Layout.fillHeight: false
            Layout.margins: 10
            title: " " + qsTr("Output Formats") + " "
            property var extensions: new Array
            Column {
                spacing: 0
                SmallCheckBox {
                    id: outMscz
                    text: "*.mscz"
                    //ButtonGroup.group: mscz
                    onClicked: {
                        if (checked && inMscz.checked)
                            inMscz.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MuseScore 3 File")
                }
                SmallCheckBox {
                    id: outMscx
                    text: "*.mscx"
                    //ButtonGroup.group: mscx
                    onClicked: {
                        if (checked && inMscx.checked)
                            inMscx.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Uncompressed MuseScore 3 File")
                }
                SmallCheckBox {
                    id: outXml
                    text: "*.xml"
                    enabled: (mscoreMajorVersion == 2 && mscoreMinorVersion <= 1) ? true : false // MuseScore <= 2.1
                    //could also export to musicxml and then rename that to xml in versions after 2.1
                    visible: enabled // hide if not enabled
                    //ButtonGroup.group: xml
                    onClicked: {
                        if (checked && inXml.checked)
                            inXml.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Uncompressed MusicXML File (outdated)")
                }
                SmallCheckBox {
                    id: outMusicXml
                    text: "*.musicxml"
                    enabled: (mscoreMajorVersion >= 3 || (mscoreMajorVersion == 2 && mscoreMinorVersion > 1)) ? true : false // MuseScore > 2.1
                    //could also export to musicxml and then rename that to xml in versions after 2.1
                    visible: enabled // hide if not enabled
                    //ButtonGroup.group: musicxml
                    onClicked: {
                        if (checked && inMusicXml.checked)
                            inMusicXml.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Uncompressed MusicXML File")
                }
                SmallCheckBox {
                    id: outMxl
                    text: "*.mxl"
                    //ButtonGroup.group: mxl
                    onClicked: {
                        if (checked && inMxl.checked)
                            inMxl.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Compressed MusicXML File")
                }
                SmallCheckBox {
                    id: outMid
                    text: "*.mid"
                    //ButtonGroup.group: mid
                    onClicked: {
                        if (checked && inMid.checked)
                            inMid.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Standard MIDI File")
                }
                SmallCheckBox {
                    id: outMidi
                    enabled: (mscoreMajorVersion >= 4 || (mscoreMajorVersion == 3 && mscoreMinorVersion >= 5)) ? true : false // MuseScore 3.5
                    visible: enabled // hide if not enabled
                    text: "*.midi"
                    //ButtonGroup.group: midi
                    onClicked: {
                        if (checked && inMidi.checked)
                            inMidi.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Standard MIDI File")
                }
                SmallCheckBox {
                    id: outPdf
                    text: "*.pdf"
                    checked: true
                    //ButtonGroup.group: pdf
                    onClicked: {
                        if (checked && inPdf.checked)
                            inPdf.checked = false
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "PDF File")
                }
                SmallCheckBox {
                    id: outPs
                    text: "*.ps"
                    enabled: (mscoreMajorVersion < 2) ? true : false // MuseScore < 2.0
                    visible: enabled // hide if not enabled
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "PostStript File")
                }
                SmallCheckBox {
                    id: outPng
                    text: "*.png"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "PNG Bitmap Graphic")
                }
                SmallCheckBox {
                    id: outSvg
                    text: "*.svg"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Scalable Vector Graphics")
                }
                SmallCheckBox {
                    id: outLy
                    text: "*.ly"
                    enabled: (mscoreMajorVersion < 2) ? true : false // MuseScore < 2.0, or via xml2ly?
                    visible: enabled // hide if not enabled
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "LilyPond Format")
                }
                SmallCheckBox {
                    id: outWav
                    text: "*.wav"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Wave Audio")
                }
                SmallCheckBox {
                    id: outFlac
                    text: "*.flac"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "FLAC Audio")
                }
                SmallCheckBox {
                    id: outOgg
                    text: "*.ogg"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "Ogg Vorbis Audio")
                }
                SmallCheckBox { // needs lame_enc.dll
                    id: outMp3
                    text: "*.mp3"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTranslate("Ms::MuseScore", "MP3 Audio")
                }
                SmallCheckBox {
                    id: outMpos
                    text: "*.mpos"
                    enabled: (mscoreMajorVersion >= 2) ? true : false // MuseScore >= 2.0
                    visible: enabled // hide if not enabled
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Positions of measures (XML)")
                }
                SmallCheckBox {
                    id: outSpos
                    text: "*.spos"
                    enabled: (mscoreMajorVersion >= 2) ? true : false // MuseScore >= 2.0
                    visible: enabled // hide if not enabled
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Positions of segments (XML)")
                }
                SmallCheckBox {
                    id: outMlog
                    text: "*.mlog"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Internal file sanity check log (JSON)")
                }
                SmallCheckBox {
                    id: outMetaJson
                    text: "*.metajson"
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Metadata JSON")
                }
            } //Column
        } //outFormats

        GridLayout {
            Layout.row: 2
            Layout.column: 2
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            rowSpacing: 1
            columnSpacing: 1
            columns: 2

            SmallCheckBox {
                id: exportExcerpts
                Layout.columnSpan: 2
                text: /*qsTr("Export linked parts")*/ qsTranslate("action", "Export parts")
                enabled: (mscoreMajorVersion == 3 && mscoreMinorVersion > 0 || (mscoreMinorVersion == 0 && mscoreUpdateVersion > 2)) ? true : false // MuseScore > 3.0.2
                visible: enabled //  hide if not enabled
            } // exportExcerpts
            SmallCheckBox {
                id: traverseSubdirs
                Layout.columnSpan: 2
                text: qsTr("Process Subdirectories")
            } // traverseSubdirs
            SmallCheckBox {
                id: filterContent
                text: qsTr("Filter files with") + ":"
            }
            RowLayout {
                spacing: 2
                TextField {
                    Layout.preferredWidth: 200
                    id: contentFilterString
                    text: ""
                    enabled: filterContent.checked
                    placeholderText: qsTr("E.g. *Concerto*")
                }
                SmallCheckBox {
                    id: filterWithRegExp
                    text: qsTr("Regular expression")
                    enabled: filterContent.checked
                    checked: true
                }
            }
            Label {
                text: qsTr("Import from")+":"
            }
            RowLayout {
                TextField {
                    Layout.preferredWidth: 400
                    id: importFrom
                    text: ""
                    enabled: false
                    color: sysActivePalette.text
                }
                Button {
                    text: qsTr("Browse")+"..."
                    onClicked: {
                        sourceFolderDialog.open()
                    }
                }
            }
            SmallCheckBox {
                id: differentExportPath
                // Only allow different export path if not traversing subdirs.
                enabled: !traverseSubdirs.checked
                property var valid: !traverseSubdirs.checked && differentExportPath.checked
                text: qsTr("Export to")+":"
                ToolTip.visible: hovered
                    ToolTip.text: qsTr("Different Export Path")
                } // differentExportPath
            RowLayout {
                TextField {
                    Layout.preferredWidth: 400
                    id: exportTo
                    text: ""
                    color: (differentExportPath.checked && differentExportPath.enabled)?sysActivePalette.text:sysActivePalette.mid//sysDisabledPalette.buttonText
                    enabled: false
                }
                Button {
                    text: qsTr("Browse")+"..."
                    enabled: differentExportPath.checked && differentExportPath.enabled
                    onClicked: {
                        targetFolderDialog.open()
                    }
                }
            }
            Button {
                Layout.columnSpan: 2
                id: reset
                text: /*qsTr("Reset to Defaults")*/ qsTranslate("QPlatformTheme", "Restore Defaults")
                onClicked: {
                    resetDefaults()
                } // onClicked
            } // reset
        } // options Column
        
        Row {
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            Layout.columnSpan: 3
            Layout.column: 1
            Layout.row: 3
            Button {
                id: preview
                text: qsTr("Preview")
                //isDefault: true // needs more work
                enabled:  (!differentExportPath.valid || exportTo.text!=="") && (importFrom.text!=="")
                onClicked: {
                    convert=false;
                    work();
                } // onClicked
            } // ok
            Button {
                id: ok
                text: /*qsTr("Ok")*/ qsTranslate("QPlatformTheme", "OK")
                onClicked: {
                    convert=true;
                    work();

                } // onClicked
            } // ok
            Button {
                id: cancel
                text: /*qsTr("Cancel")*/ qsTranslate("QPlatformTheme", "Close")
                onClicked: {
                    batchConvert.parent.Window.window.close();
                }
            } // Cancel
        } // Row
    } // GridLayout
    //} // Window
    // remember settings
    Settings {
        id: settings
        category: "BatchConvertPlugin"
        // in options
        property alias inMscz:  inMscz.checked
        property alias inMscx:  inMscx.checked
        property alias inMsc:   inMsc.checked
        property alias inXml:   inXml.checked
        property alias inMusicXml: inMusicXml.checked
        property alias inMxl:   inMxl.checked
        property alias inMid:   inMid.checked
        property alias inMidi:  inMidi.checked
        property alias inKar:   inKar.checked
        property alias inMd:    inMd.checked
        property alias inPdf:   inPdf.checked
        property alias inCap:   inCap.checked
        property alias inCapx:  inCapx.checked
        property alias inMgu:   inMgu.checked
        property alias inSgu:   inSgu.checked
        property alias inOve:   inOve.checked
        property alias inScw:   inScw.checked
        property alias inBmw:   inBmw.checked
        property alias inBww:   inBww.checked
        property alias inGtp:   inGtp.checked
        property alias inGp3:   inGp3.checked
        property alias inGp4:   inGp4.checked
        property alias inGp5:   inGp5.checked
        property alias inGpx:   inGpx.checked
        property alias inGp:    inGp.checked
        property alias inPtb:   inPtb.checked
        property alias inMsczComma: inMsczComma.checked
        property alias inMscxComma: inMscxComma.checked
        // out options
        property alias outMscz: outMscz.checked
        property alias outMscx: outMscx.checked
        property alias outXml:  outXml.checked
        property alias outMusicXml: outMusicXml.checked
        property alias outMxl:  outMxl.checked
        property alias outMid:  outMid.checked
        property alias outMidi: outMidi.checked
        property alias outPdf:  outPdf.checked
        property alias outPs:   outPs.checked
        property alias outPng:  outPng.checked
        property alias outSvg:  outSvg.checked
        property alias outLy:   outLy.checked
        property alias outWav:  outWav.checked
        property alias outFlac: outFlac.checked
        property alias outOgg:  outOgg.checked
        property alias outMp3:  outMp3.checked
        property alias outMpos: outMpos.checked
        property alias outSpos: outSpos.checked
        property alias outMlog: outMlog.checked
        property alias outMetaJson: outMetaJson.checked
        // other options
        property alias exportE: exportExcerpts.checked
        property alias travers: traverseSubdirs.checked
        property alias diffEPath: differentExportPath.checked  // different export path
        property alias iPath: importFrom.text // import path
        property alias ePath: exportTo.text // export path
        property alias filter: filterContent.checked
        property alias filterString: contentFilterString.text
        property alias filterIsRegExp: filterWithRegExp.checked

    }
    
    FileDialog {
        id: sourceFolderDialog
        title: traverseSubdirs.checked ?
                   qsTr("Select Sources Startfolder"):
                   qsTr("Select Sources Folder")
        selectFolder: true
        folder: Qt.resolvedUrl(importFrom.text);
       

        onAccepted: {
            importFrom.text = sourceFolderDialog.folder.toString();
        }
        onRejected: {
            console.log("No source folder selected")
        }

    } // sourceFolderDialog

    FileDialog {
        id: targetFolderDialog
        title: qsTr("Select Target Folder")
        selectFolder: true
        folder: Qt.resolvedUrl(exportTo.text);

        onAccepted: {
            exportTo.text = targetFolderDialog.folder.toString();
        }

        onRejected: {
            console.log("No target folder selected")
        }
    } // targetFolderDialog
    
    function urlToPath(urlString) {
        var s;
        if (urlString.startsWith("file:///")) {
            var k = urlString.charAt(9) === ':' ? 8 : 7
            s = urlString.substring(k)
        } else {
            s = urlString
        }
        return decodeURIComponent(s);
} 

    function resetDefaults() {
        inMscx.checked = inXml.checked = inMusicXml.checked = inMxl.checked = inMid.checked =
                inMidi.checked = inKar.checked = inMd.checked = inPdf.checked = inCap.checked =
                inCapx.checked = inMgu.checked = inSgu.checked = inOve.checked = inScw.checked =
                inBmw.checked = inBww.checked = inGp4.checked = inGp5.checked = inGpx.checked =
                inGp.checked = inPtb.checked = inMsczComma.checked = inMscxComma.checked = false
        outMscz.checked = outMscx.checked = outXml.checked = outMusicXml.checked = outMxl.checked =
                outMid.checked = outMidi.checked = outPdf.checked = outPs.checked = outPng.checked =
                outSvg.checked = outLy.checked = outWav.checked = outFlac.checked =
                outOgg.checked = outMp3.checked = outMpos.checked = outSpos.checked =
                outMlog.checked = outMetaJson.checked = false
        traverseSubdirs.checked = false
        exportExcerpts.checked = false
        filterWithRegExp.checked=true;
        filterContent.checked=true;
        contentFilterString.text="";
        // 'uncheck' everything, then 'check' the next few
        inMscz.checked = outPdf.checked = true
        differentExportPath.checked = false
    } // resetDefaults

    function collectInOutFormats() {
        inFormats.extensions.length=0;
        outFormats.extensions.length=0;
        if (inMscz.checked) inFormats.extensions.push("mscz")
        if (inMscx.checked) inFormats.extensions.push("mscx")
        if (inXml.checked)  inFormats.extensions.push("xml")
        if (inMusicXml.checked) inFormats.extensions.push("musicxml")
        if (inMxl.checked)  inFormats.extensions.push("mxl")
        if (inMid.checked)  inFormats.extensions.push("mid")
        if (inMidi.checked) inFormats.extensions.push("midi")
        if (inKar.checked)  inFormats.extensions.push("kar")
        if (inMd.checked)   inFormats.extensions.push("md")
        if (inPdf.checked)  inFormats.extensions.push("pdf")
        if (inCap.checked)  inFormats.extensions.push("cap")
        if (inCapx.checked) inFormats.extensions.push("capx")
        if (inMgu.checked)  inFormats.extensions.push("mgu")
        if (inSgu.checked)  inFormats.extensions.push("sgu")
        if (inOve.checked)  inFormats.extensions.push("ove")
        if (inScw.checked)  inFormats.extensions.push("scw")
        if (inBmw.checked)  inFormats.extensions.push("bmw")
        if (inBww.checked)  inFormats.extensions.push("bww")
        if (inGtp.checked)  inFormats.extensions.push("gtp")
        if (inGp3.checked)  inFormats.extensions.push("gp3")
        if (inGp4.checked)  inFormats.extensions.push("gp4")
        if (inGp5.checked)  inFormats.extensions.push("gp5")
        if (inGpx.checked)  inFormats.extensions.push("gpx")
        if (inGp.checked)   inFormats.extensions.push("gp")
        if (inPtb.checked)  inFormats.extensions.push("ptb")
        if (inMsczComma.checked) inFormats.extensions.push("mscz,")
        if (inMscxComma.checked) inFormats.extensions.push("mscx,")
        if (!inFormats.extensions.length)
            console.warn("No input format selected")

        if (outMscz.checked) outFormats.extensions.push("mscz")
        if (outMscx.checked) outFormats.extensions.push("mscx")
        if (outXml.checked)  outFormats.extensions.push("xml")
        if (outMusicXml.checked) outFormats.extensions.push("musicxml")
        if (outMxl.checked)  outFormats.extensions.push("mxl")
        if (outMid.checked)  outFormats.extensions.push("mid")
        if (outMidi.checked) outFormats.extensions.push("midi")
        if (outPdf.checked)  outFormats.extensions.push("pdf")
        if (outPs.checked)   outFormats.extensions.push("ps")
        if (outPng.checked)  outFormats.extensions.push("png")
        if (outSvg.checked)  outFormats.extensions.push("svg")
        if (outLy.checked)   outFormats.extensions.push("ly")
        if (outWav.checked)  outFormats.extensions.push("wav")
        if (outFlac.checked) outFormats.extensions.push("flac")
        if (outOgg.checked)  outFormats.extensions.push("ogg")
        if (outMp3.checked)  outFormats.extensions.push("mp3")
        if (outMpos.checked) outFormats.extensions.push("mpos")
        if (outSpos.checked) outFormats.extensions.push("spos")
        if (outMlog.checked) outFormats.extensions.push("mlog")
        if (outMetaJson.checked) outFormats.extensions.push("metajson")
        if (!outFormats.extensions.length)
            console.warn("No output format selected")

        return (inFormats.extensions.length && outFormats.extensions.length)
    } // collectInOutFormats

    // flag for abort request
    property bool abortRequested: false

    // dialog to show progress
    Dialog {
        id: workDialog
        modality: Qt.ApplicationModal
        visible: false
        width: 900
        height: 700
        standardButtons: StandardButton.Abort
        

        ColumnLayout {

            anchors.fill: parent
            spacing: 5
            anchors.topMargin: 10
            anchors.rightMargin: 10
            anchors.leftMargin: 10
            anchors.bottomMargin: 5

            Label {
                id: currentStatus
                Layout.preferredWidth: 600
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                text: qsTr("Running...")
            }

            ScrollView {
                id: view
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 700
                clip: true
                TextArea {
                    id: resultText
                    //anchors.fill: parent
                    anchors.margins: 5
                    selectByMouse: true
                    selectByKeyboard: true
                    cursorVisible: true
                    readOnly: true
                    focus: true
                }

            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.position: 0
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            }
            
        }

        onRejected: {
            abortRequested = true
        }
    }

    function inInputFormats(suffix) {
        var found = false

        for (var i = 0; i < inFormats.extensions.length; i++) {
            if (inFormats.extensions[i].toUpperCase() === suffix.toUpperCase()) {
                found = true
                break
            }
        }
        return found
    }

    // createDefaultFileName
    // remove some special characters in a score title
    // when creating a file name
    function createDefaultFileName(fn) {
        fn = fn.trim()
        fn = fn.replace(/ /g,"_")
        fn = fn.replace(/ /g,"_")
        fn = fn.replace(/[\\\/:\*\?\"<>|]/g,"_")
        return fn
    }

    // global list of folders to process
    property var folderList
    // global list of files to process
    property var fileList
    // global list of linked parts to process
    property var excerptsList

    // variable to remember current parent score for parts
    property var curBaseScore

    // FolderListModel can be used to search the file system
    FolderListModel {
        id: files
    }

    FileIO {
        id: fileExcerpt
    }

    FileIO {
        id: fileScore // We need two because they they are used from 2 different processes,
        // which could cause threading problems
    }

    Timer {
        id: excerptTimer
        interval: 1
        running: false

        // this function processes one linked part and
        // gives control back to Qt to update the dialog
        onTriggered: {
            var curScoreInfo = excerptsList.shift()
            var thisScore = curScoreInfo[0].partScore
            var partTitle = curScoreInfo[0].title
            var filePath = curScoreInfo[1]
            var fileName = curScoreInfo[2]
            var srcModifiedTime = curScoreInfo[3]

            // create full file path for part
            var targetBase;
            if (differentExportPath.checked && !traverseSubdirs.checked)
                targetBase = exportToPath + "/" + fileName
                        + "-" + createDefaultFileName(partTitle) + "."
            else
                targetBase = filePath + fileName + "-" + createDefaultFileName(partTitle) + "."

            // write for all target formats
            for (var j = 0; j < outFormats.extensions.length; j++) {
                // get modification time of destination file (if it exists)
                // modifiedTime() will return 0 for non-existing files
                // if src is newer than existing write this file
                fileExcerpt.source = targetBase + outFormats.extensions[j]
                if (srcModifiedTime > fileExcerpt.modifiedTime()) {
                    var res = convert?writeScore(thisScore, fileExcerpt.source, outFormats.extensions[j]):true;
                    if (res)
                        resultText.append("  %1 → %2: %3".arg(partTitle).arg(outFormats.extensions[j]).arg(fileExcerpt.source))
                    else
                        resultText.append("  "+qsTr("Error: %1 → %2 not exported").arg(partTitle).arg(outFormats.extensions[j]))
                }
                else // file already up to date
                    resultText.append("  "+qsTr("%1 is up to date").arg(fileExcerpt.source))
            }

            // check if more files
            if (!abortRequested && excerptsList.length > 0)
                excerptTimer.running = true
            else {
                // close base score
                closeScore(curBaseScore)
                processTimer.restart();
            }
        }
    }

    Timer {
        id: processTimer
        interval: 1
        running: false

        // this function processes one file and then
        // gives control back to Qt to update the dialog
        onTriggered: {
            if (fileList.length === 0) {
                // no more files to process
                workDialog.standardButtons = StandardButton.Ok
                if (!abortRequested)
                    currentStatus.text = /*qsTr("Done.")*/ qsTranslate("QWizzard", "Done") + "."
                else
                    console.log("abort!")
                return
            }

            console.log("--Remaing items to convert: "+fileList.length+"--");

            var curFileInfo = fileList.shift()
            var filePath = curFileInfo[0]
            var fileName = curFileInfo[1]
            var fileExt = curFileInfo[2]

            var fileFullPath = filePath + fileName + "." + fileExt

            // read file
            var thisScore = readScore(fileFullPath, true)

            // make sure we have a valid score
            if (thisScore) {
                // get modification time of source file
                fileScore.source = fileFullPath
                var srcModifiedTime = fileScore.modifiedTime()
                // write for all target formats
                for (var j = 0; j < outFormats.extensions.length; j++) {
                    if (differentExportPath.checked && !traverseSubdirs.checked)
                        fileScore.source = exportToPath + "/" + fileName + "." + outFormats.extensions[j]
                    else
                        fileScore.source = filePath + fileName + "." + outFormats.extensions[j]

                    // get modification time of destination file (if it exists)
                    // modifiedTime() will return 0 for non-existing files
                    // if src is newer than existing write this file
                    if (srcModifiedTime > fileScore.modifiedTime()) {
                        var res = convert?writeScore(thisScore, fileScore.source, outFormats.extensions[j]):true

                        if (res)
                            resultText.append("%1 → %2: %3".arg(fileFullPath).arg(outFormats.extensions[j]).arg(fileScore.source))
                        else
                            resultText.append(qsTr("Error: %1 → %2 not exported").arg(fileFullPath).arg(outFormats.extensions[j]))
                    }
                    else
                        resultText.append(qsTr("%1 is up to date").arg(fileFullPath))
                }
                // check if we are supposed to export parts
                if (exportExcerpts.checked) {
                    // reset list
                    excerptsList = []
                    // do we have excertps?
                    var excerpts = thisScore.excerpts
                    for (var ex = 0; ex < excerpts.length; ex++) {
                        if (excerpts[ex].partScore !== thisScore) // only list when not base score
                            excerptsList.push([excerpts[ex], filePath, fileName, srcModifiedTime])
                    }
                    // if we have files start timer
                    if (excerpts.length > 0) {
                        curBaseScore = thisScore // to be able to close this later
                        excerptTimer.running = true
                        return
                    }
                }
                closeScore(thisScore)
            }
            else
                resultText.append(qsTr("ERROR reading file %1").arg(fileName))

            // next file
            if (!abortRequested)
                processTimer.restart();
        }
    }

    // FolderListModel returns what Qt calles the
    // completeSuffix for "fileSuffix" which means everything
    // that follows the first '.' in a file name. (e.g. 'tar.gz')
    // However, this is not what we want:
    // For us the suffix is the part after the last '.'
    // because some users have dots in their file names.
    // Qt::FileInfo::suffix() would get this, but seems not
    // to be available in FolderListModel.
    // So, we need to do this ourselves:
    function getFileSuffix(fileName) {

        var n = fileName.lastIndexOf(".");
        var suffix = fileName.substring(n+1);

        return suffix
    }

    // This timer contains the function that will be called
    // once the FolderListModel is set.
    Timer {
        id: collectFiles
        interval: 25
        running: false

        // Add all files found by FolderListModel to our list
        onTriggered: {
            // to be able to show what we're doing
            // we must create a list of files to process
            // and then use a timer to do the work
            // otherwise, the dialog window will not update

            var regexp;
            if (filterContent.checked) {
                try {
                    regexp=filterWithRegExp.checked?new RegExp(contentFilterString.text): RegExp('^' + contentFilterString.text.replace(/\*/g, '.*') + '$');
                } catch(err) {
                    resultText.append(err.message);
                    workDialog.standardButtons = StandardButton.Ok
                    return;
                }
            }

            for (var i = 0; i < files.count; i++) {

                // if we have a directory, we're supposed to
                // traverse it, so add it to folderList
                if (files.isFolder(i))
                    folderList.push(files.get(i, "fileURL"))
                else if (inInputFormats(getFileSuffix(files.get(i, "fileName")))) {
                    // found a file to process
                    // set file names for in and out files

                    // We need 3 things:
                    // 1) The file path: C:/Path/To/
                    // 2) The file name:            my_score
                    //                                      .
                    // 3) The file's extension:              mscz

                    var fln = files.get(i, "fileName") // returns  "my_score.mscz"
                    var flp = files.get(i, "filePath") // returns  "C:/Path/To/my_score.mscz"

                    var fileExt  = getFileSuffix(fln);  // mscz
                    var fileName = fln.substring(0, fln.length - fileExt.length - 1)
                    var filePath = flp.substring(0, flp.length - fln.length)

                    /// in doubt uncomment to double check
                    // console.log("fln", fln)
                    // console.log("flp", flp)
                    // console.log("fileExt", fileExt)
                    // console.log("fileName", fileName)
                    // console.log("filePath", filePath)

                    var match=true;
                    if (regexp) {
                        // console.log("--Filter files--");
                        // console.log(filterWithRegExp.checked?"--RegExp--":"--Regular--");
                        // console.log("--with \""+contentFilterString.text+"\"--");
                        match=regexp.test(fileName);
                        // console.log("Match RegExp: ", match)
                    } else {
                        // console.log("--Don't filter files--");
                    }

                    if (match)
                        fileList.push([filePath, fileName, fileExt])
                }
            }

            // if folderList is non-empty we need to redo this for the next folder
            if (folderList.length > 0) {
                files.folder = folderList.shift()
                // restart timer for folder search
                collectFiles.running = true
            } else if (fileList.length > 0) {
                // if we found files, start timer do process them
                processTimer.restart();
            }
            else {
                // we didn't find any files
                // report this
                resultText.append(qsTr("No files found"))
                workDialog.standardButtons = StandardButton.Ok
                currentStatus.text = /*qsTr("Done.")*/ qsTranslate("QWizzard", "Done") + "."
            }
        }
    }

    function work() {
        
        if (!collectInOutFormats())
            return;

        if (resultText.text!=="") resultText.append("---------------------------------");
        workDialog.visible = true

        if(!importFrom.text) {
            resultText.append(qsTr("Missing import folder"));
            return;
        }
        if (differentExportPath.checked && !traverseSubdirs.checked && !exportTo.text) {
            resultText.append(qsTr("Missing export folder"));
            return;
        }

        // remove the file:/// at the beginning of the return value of targetFolderDialog.folder
        // However, what needs to be done depends on the platform.
        // See this stackoverflow post for more details:
        // https://stackoverflow.com/questions/24927850/get-the-path-from-a-qml-url
        exportToPath = urlToPath(exportTo.text);                    

        console.log(exportToPath);
        
        console.log((traverseSubdirs.checked? "Sources Startfolder: ":"Sources Folder: ")
                    + importFrom.text)

        if (differentExportPath.checked && !traverseSubdirs.checked)
            console.log("Export folder: " + exportTo.text)

        // initialize global variables
        fileList = []
        folderList = []

        // set folder and filter in FolderListModel
        files.folder = importFrom.text

        if (traverseSubdirs.checked) {
            files.showDirs = true
            files.showFiles = true
        }
        else {
            // only look for files
            files.showFiles = true
            files.showDirs = false
        }

        // wait for FolderListModel to update
        // therefore we start a timer that will
        // wait for 25 millis and then start working
        collectFiles.running = true
    } // work
} // MuseScore
