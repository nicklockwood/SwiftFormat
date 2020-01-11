import * as core from "@actions/core"
// import * as github from "@actions/github"

async function run(): Promise<void> {
    try {

        const filesToSort = core.getInput("args")
        
        const { execSync } = require("child_process")
        execSync("CommandLineTool/swiftformat . --swiftversion 5 --rules indent,linebreaks --exclude Pods,.build --verbose")

    } catch (error) {
        core.setFailed(error.message)
    }
}

run()
