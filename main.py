

from flask import Flask, request, Response
import os
import json

app = Flask(__name__)
port = 8000

@app.route('/', methods=['GET'])
def index():
    return """
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
    """

@app.route('/send-message', methods=['POST'])
def send_message():
    message = request.form.get('message', '')
    print(f'Message received: {message}')
    return 'Message sent to the server'

@app.route('/download-file', methods=['GET'])
def download_file():
    filePath = os.path.join(os.getcwd(), request.args.get('path', ''))
    try:
        with open(filePath, 'rb') as f:
            file_data = f.read()
        response = Response(file_data)
        response.headers['Content-Disposition'] = 'attachment; filename=' + os.path.basename(filePath)
        return response
    except Exception as e:
        print(e)
        return 'Error downloading the file', 500

@app.route('/browse-folder', methods=['GET'])
def browse_folder():
    folderPath = os.path.join(os.getcwd(), request.args.get('path', ''))
    try:
        files = os.listdir(folderPath)
        file_data = []
        for file in files:
            filePath = os.path.join(folderPath, file)
            isDirectory = os.path.isdir(filePath)
            isSymbolicLink = os.path.islink(filePath)
            file_data.append({'name': file, 'isDirectory': isDirectory, 'isSymbolicLink': isSymbolicLink})
        return json.dumps(file_data)
    except Exception as e:
        print(e)
        return 'Error reading the folder', 500

@app.route('/preview-file/<path:file_name>', methods=['GET'])
def preview_file(file_name):
    filePath = os.path.join(os.getcwd(), file_name)
    try:
        with open(filePath, 'r') as f:
            file_data = f.read()
        return_txt = """
        <html><body><code class="codeblock language-python">""" + file_data + """</code></body></html>"""
        return return_txt
    except Exception as e:
        print(e)
        return 'Error previewing the file', 500

if __name__ == '__main__':
    app.run(port=port, debug=True)
