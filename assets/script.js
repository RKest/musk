const PROGRESS_BAR_ID = 'progress-bar';
const DROP_AREA_ID = 'drop-area';
let filesDone = 0;
let filesToDo = 0;

(function(){
    const dropArea = document.getElementById(DROP_AREA_ID);

    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropArea.addEventListener(eventName, (e) => {
            e.preventDefault();
            e.stopPropagation();
        });
    });

    ['dragenter', 'dragover'].forEach(eventName => {
        dropArea.addEventListener(eventName, (_) => 
            dropArea.classList.add('highlight')
        );
    });
      
    ['dragleave', 'drop'].forEach(eventName => {
        dropArea.addEventListener(eventName, (_) => 
            dropArea.classList.remove('highlight')
        );
    });

    dropArea.addEventListener('drop', handleDrop)
})();

function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    initializeProgress(files.length);
    handleFiles(files);
}

function handleFiles(files) {
  ([...files]).forEach(uploadFile)
}

function sendFile(file) {
    const action = document.getElementById(DROP_AREA_ID).getAttribute("action");

    var xhr = new XMLHttpRequest();
    xhr.open('POST', action, true);
    xhr.setRequestHeader('Content-Type', 'multipart/form-data');

    // Add following event listener
    xhr.upload.addEventListener("progress", function(e) {
      updateProgress(i, (e.loaded * 100.0 / e.total) || 100);
    });
  
    xhr.addEventListener('readystatechange', function(e) {
      if (xhr.readyState == 4 && xhr.status == 200) {
        // Done. Inform the user
      }
      else if (xhr.readyState == 4 && xhr.status != 200) {
        // Error. Inform the user
      }
    });
  
    const formData = new FormData();
    formData.append('file', file);
    xhr.send(formData);
}

function initializeProgress(numfiles) {
    const progressBar = document.getElementById(PROGRESS_BAR_ID);
    progressBar.value = 0;
    filesDone = 0;
    filesToDo = numfiles;
}

function progressDone() {
    filesDone++;
    const progressBar = document.getElementById(PROGRESS_BAR_ID);
    progressBar.value = filesDone / filesToDo * 100;
  }

  function uploadFile(file, i) { // <- Add `i` parameter
    var url = 'YOUR URL HERE'
    var xhr = new XMLHttpRequest()
    var formData = new FormData()
    xhr.open('POST', url, true)
  
    // Add following event listener
    xhr.upload.addEventListener("progress", function(e) {
      updateProgress(i, (e.loaded * 100.0 / e.total) || 100)
    })
  
    xhr.addEventListener('readystatechange', function(e) {
      if (xhr.readyState == 4 && xhr.status == 200) {
        // Done. Inform the user
      }
      else if (xhr.readyState == 4 && xhr.status != 200) {
        // Error. Inform the user
      }
    })
  
    formData.append('file', file)
    xhr.send(formData)
  }  