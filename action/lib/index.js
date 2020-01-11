"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const github = __importStar(require("@actions/github"));
class ChangedFiles {
    constructor() {
        this.updated = [];
        this.created = [];
        this.deleted = [];
    }
}
function getPrNumber() {
    const pullRequest = github.context.payload.pull_request;
    return pullRequest ? pullRequest.number : null;
}
function getChangedFiles(client, prNumber) {
    return __awaiter(this, void 0, void 0, function* () {
        const listFilesResponse = yield client.pulls.listFiles({
            owner: github.context.repo.owner,
            repo: github.context.repo.repo,
            pull_number: prNumber,
        });
        console.log("Found changed files:");
        return listFilesResponse.data.reduce((acc, f) => {
            console.log(f);
            if (f.status === "added") {
                acc.created.push(f.filename);
            }
            else if (f.status === "removed") {
                acc.deleted.push(f.filename);
            }
            else if (f.status === "modified") {
                acc.updated.push(f.filename);
            }
            else if (f.status === "renamed") {
                acc.created.push(f.filename);
                acc.deleted.push(f["previous_filename"]);
            }
            return acc;
        }, new ChangedFiles());
    });
}
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const token = core.getInput("repo-token", { required: true });
            const client = new github.GitHub(token);
            const prNumber = getPrNumber();
            if (prNumber == null) {
                core.setFailed("Could not get pull request number from context, exiting");
                return;
            }
            const filesToSort = core.getInput("args");
            const { execSync } = require("child_process");
            execSync("CommandLineTool/swiftformat . --swiftversion 5 --rules indent,linebreaks --exclude Pods,.build --verbose");

            core.debug(`Fetching changed files for pr #${prNumber}`);
            const changedFiles = yield getChangedFiles(client, prNumber);

            console.log(`The event created: ${changedFiles.created.join(" ")}`);
            console.log(`The event updated: ${changedFiles.updated.join(" ")}`);
            console.log(`The event deleted: ${changedFiles.deleted.join(" ")}`);
        }
        catch (error) {
            core.setFailed(error.message);
        }
    });
}
run();
