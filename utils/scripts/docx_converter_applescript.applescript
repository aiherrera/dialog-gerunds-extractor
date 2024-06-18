on run argv
    set docPath to item 1 of argv
    set docxPath to item 2 of argv
    tell application "Microsoft Word"
        open file name docPath
        set theDoc to the active document
        save as theDoc file format format document file name docxPath
        close theDoc
    end tell
end run
