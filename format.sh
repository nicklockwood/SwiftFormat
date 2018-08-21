if [[ -z "${TRAVIS}" ]]; then
    CommandLineTool/swiftformat . --cache ignore
fi
