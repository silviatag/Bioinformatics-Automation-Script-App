import express, { response } from "express";
import multer from "multer";
import { exec } from "child_process";
import path from "path";
import fs from "fs";
import { v4 as uuidv4 } from "uuid";
import cors from "cors";

const app = express();
app.use(cors());

// Define absolute paths
const __dirname = path.resolve();
const uploadDir = path.join(__dirname, "uploads");
const outputDir = path.join(__dirname, "outputs");

// Ensure folders exist
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

// 2. CLEANUP LOGIC (Add this here)
const cleanOldFiles = () => {
    const twentyFourHoursAgo = Date.now() - 24 * 60 * 60 * 1000;

    // Helper to clean a specific directory
    const cleanDir = (dirPath) => {
        fs.readdir(dirPath, (err, items) => {
            if (err) return;
            items.forEach((item) => {
                const fullPath = path.join(dirPath, item);
                fs.stat(fullPath, (err, stats) => {
                    if (err) return;
                    if (stats.mtimeMs < twentyFourHoursAgo) {
                        fs.rm(fullPath, { recursive: true, force: true }, () => {
                            console.log(`Cleaned up: ${item}`);
                        });
                    }
                });
            });
        });
    };

    cleanDir(outputDir); // Clean processed jobs
    cleanDir(uploadDir); // Clean raw uploaded MSA files
};

// Run cleanup every hour
setInterval(cleanOldFiles, 60 * 60 * 1000);

// Serve outputs folder: http://localhost:3000/outputs/...
app.use("/outputs", express.static(outputDir));

const upload = multer({ dest: uploadDir });

// ... (keep your imports and setup as they were)

app.post("/api/phylogeneticTree", upload.single("msa"), (req, res) => {
  const jobId = uuidv4();
  const file = req.file.path;
  const type = req.body.type?.toUpperCase();
  const scriptPath = path.join(process.cwd(), "scripts", "phylogeneticTreeConstruction.sh");

  const cmd = `bash "${scriptPath}" "${file}" "${type}" "${jobId}"`;

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("Script Error:", stderr);
      return res.status(500).json({ error: "Tree construction failed." });
    }

    // --- THE KEY FIX IS HERE ---
    // We do NOT use the path the script gives us. 
    // We build the URL based on the jobId because Express is serving the 'outputs' folder.
    
    const host = req.get("host"); // This gets "localhost:3000"
    const protocol = req.protocol; // This gets "http"
    
    const publicTreeUrl = `${protocol}://${host}/outputs/${jobId}/tree.newick`;
    const publicImageUrl = `${protocol}://${host}/outputs/${jobId}/tree.png`;

    console.log("generated url: ", publicTreeUrl);
    // Verify the file exists on the server's disk before telling the frontend it's ready
    const localTreePath = path.join(process.cwd(), "outputs", jobId, "tree.newick");

    if (fs.existsSync(localTreePath)) {
      res.json({
        tree: publicTreeUrl,  // Sending the URL, not the local path!
        image: publicImageUrl,
        jobId,
        rawOutput: stdout // Keeping this for your debugging
      });
      console.log("response:", res);
    } else {
      res.status(500).json({ 
        error: "Files were not generated.",
        debugPath: localTreePath 
      });
    }
  });
});

app.listen(3000, () => console.log("Backend running on port 3000"));