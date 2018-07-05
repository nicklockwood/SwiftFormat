if [[ -z "${TRAVIS}" ]]; then
    CommandLineTool/swiftformat . --experimental enabled --cache ignore
fi
