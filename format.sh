if [[ -z "${TRAVIS}" ]]; then
    CommandLineTool/swiftformat . --config .swiftformat --cache ignore
fi
