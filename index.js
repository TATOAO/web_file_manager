const express = require('express');
const path = require('path');


const fs = require('fs');
const { isSymbol } = require('util');
const app = express();
const port = 8000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
const folder_path = "./shared_folder/"

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <style>
          .indent {
            margin-left: 20px;
          }
        </style>
        <script>
          function toggleFolder(folderId) {
            const folder = document.getElementById(folderId);
            folder.style.display = folder.style.display === 'none' ? 'block' : 'none';
          }
        </script>
      </head>
      <body>
        <div id="folder-container"></div>
        <script>
          async function fetchFolder(folderPath) {
            const response = await fetch('/browse-folder?path=' + encodeURIComponent(folderPath));
            const files = await response.json();
            return files;
          }

          async function renderFolder(folderPath, container) {
            const files = await fetchFolder(folderPath);
            files.forEach(file => {
              const fileElement = document.createElement('div');
              fileElement.textContent = (file.isDirectory ? '-' : '') + file.name;
              container.appendChild(fileElement);
              if (file.isDirectory || file.isSymbolicLink) {
                fileElement.style.cursor = 'pointer';
                fileElement.addEventListener('dblclick', async () => {
                  const subFolderPath = folderPath + '/' + file.name;
                  const subFolderContainer = document.createElement('div');
                  subFolderContainer.style.display = 'none';
                  subFolderContainer.id = subFolderPath;
                  subFolderContainer.className = 'indent';
                  container.appendChild(subFolderContainer);
                  await renderFolder(subFolderPath, subFolderContainer);
                  toggleFolder(subFolderPath);
                });
              } else {
                fileElement.style.cursor = 'pointer';
                let clickTimer;
                fileElement.addEventListener('click', () => {
                  clearTimeout(clickTimer);
                  clickTimer = setTimeout(() => {
                    const previewPath = '/preview-file/' + encodeURIComponent(folderPath + '/' + file.name);
                    window.open(previewPath, '_blank');
                  }, 250);
                });
                fileElement.addEventListener('dblclick', (event) => {
                  event.preventDefault();
                  clearTimeout(clickTimer);
                  const downloadPath = '/download-file?path=' + encodeURIComponent(folderPath + '/' + file.name);
                  window.location.href = downloadPath;
        				});
              }
            });
          }

          renderFolder('.', document.getElementById('folder-container'));
        </script>
      </body>
    </html>
  `);
});
app.post('/send-message', (req, res) => {
  const message = req.body.message;
  console.log(`Message received: ${message}`);
  res.send('Message sent to the server');
});

app.get('/download-file', (req, res) => {
  const filePath = path.join(__dirname, req.query.path);
  res.download(filePath, (err) => {
    if (err) {
      console.error(err);
      res.status(500).send('Error downloading the file');
    }
  });
});

app.get('/browse-folder', (req, res) => {
  const folderPath = path.join(__dirname, req.query.path);
  fs.readdir(folderPath, { withFileTypes: true }, (err, files) => {
    if (err) {
      console.error(err);
      res.status(500).send('Error reading the folder');
    } else {
      const fileData = files.map(file => ({
        name: file.name,
        isDirectory: file.isDirectory(),
        isSymbolicLink: file.isSymbolicLink()
      }));
      res.json(fileData);
    }
  });
});

app.get('/preview-file/:fileName', (req, res) => {
  const fileName = req.params.fileName;
  console.log(fileName);
  const filePath = path.join(__dirname, fileName);
  res.sendFile(filePath);
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});