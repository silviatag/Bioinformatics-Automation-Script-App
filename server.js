import express from "express";
import multer from "multer";
import { exec } from "child_process";
import path from "path";
import fs from "fs";
import { v4 as uuidv4 } from "uuid";
import cors from "cors";

const app = express();

// --- CORS Setup ---
const FRONTEND_URL = "https://seqflow-kappa.vercel.app";

app.use(cors({
  origin: FRONTEND_URL,      // allow requests from your frontend
  methods: ['GET','POST'],
  credentials: true
}));

// Define absolute paths
const __dirname = path.resolve();
const uploadDir = path.join(__dirname, "uploads");
const outputDir = path.join(__dirname, "outputs");

// Ensure folders exist
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

// --- Cleanup logic ---
const cleanOldFiles = () => {
    const twentyFourHoursAgo = Date.now() - 24 * 60 * 60 * 1000;

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

    cleanDir(outputDir);
    cleanDir(uploadDir);
};

// Run cleanup every hour
setInterval(cleanOldFiles, 60 * 60 * 1000);

// --- Serve outputs folder with download headers ---
app.use("/outputs", express.static(outputDir, {
  setHeaders: (res, filePath) => {
    if (filePath.endsWith(".newick") || filePath.endsWith(".nwk")) {
      res.setHeader("Content-Disposition", 'attachment; filename="tree.newick"');
      res.setHeader("Content-Type", "text/plain");
    }
    if (filePath.endsWith(".png")) {
      res.setHeader("Content-Type", "image/png");
    }
    if (filePath.endsWith(".fasta") || filePath.endsWith(".fa")) {
      res.setHeader("Content-Disposition", `attachment; filename="${path.basename(filePath)}"`);
      res.setHeader("Content-Type", "application/octet-stream");
    }
  }
}));

const upload = multer({ dest: uploadDir });

// --- Phylogenetic Tree API ---
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

    const host = req.get("host");
    const protocol = req.protocol;

    const publicTreeUrl = `${protocol}://${host}/outputs/${jobId}/tree.newick`;
    const publicImageUrl = `${protocol}://${host}/outputs/${jobId}/tree.png`;

    console.log("generated url: ", publicTreeUrl);

    const localTreePath = path.join(outputDir, jobId, "tree.newick");

    if (fs.existsSync(localTreePath)) {
      res.json({
        tree: publicTreeUrl,
        image: publicImageUrl,
        jobId,
        rawOutput: stdout
      });
    } else {
      res.status(500).json({ 
        error: "Files were not generated.",
        debugPath: localTreePath
      });
    }
  });
});

// --- Database Retrieval API ---
app.post("/api/dbRetrieval", express.json(), (req, res) => {
  const { choice, keyword } = req.body;

  if (!choice || !keyword) {
    return res.status(400).json({
      error: "Missing parameters. Required: choice and keyword"
    });
  }

  const jobId = uuidv4();

  const scriptPath = path.join(
    process.cwd(),
    "scripts",
    "dbRetrieval.sh"
  );

  const cmd = `bash "${scriptPath}" "${choice}" "${keyword}" "${jobId}"`;

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      console.error("DB Script Error:", stderr);
      return res.status(500).json({
        error: "Database retrieval failed"
      });
    }

    const host = req.get("host");
    const protocol = req.protocol;

    const fastaFileName = `${keyword}.fasta`;
    const publicFastaUrl = `${protocol}://${host}/outputs/${jobId}/${fastaFileName}`;

    console.log("generated fasta file url: ", publicFastaUrl );
    
    const localFastaPath = path.join(
      outputDir,
      jobId,
      fastaFileName
    );

    if (!fs.existsSync(localFastaPath)) {
      return res.status(500).json({
        error: "FASTA file was not generated",
        debugPath: localFastaPath
      });
    }

    res.json({
      fasta: publicFastaUrl,
      jobId,
      rawOutput: stdout
    });
  });
});


// --- Health Check ---
app.get('/health-check', (req, res) => {
  res.status(200).send('OK');
});

// --- Start Server ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
