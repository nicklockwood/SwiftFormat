swift package plugin --allow-writing-to-package-directory format-source-code --unexclude .
if [[ `git status --porcelain` ]]; then
    # Expected changes
    git restore Sources/PackageUsingPlugin/NotFormattedFile.swift
    exit 0
else
    # No changes - unexpected
    exit 1
fi
