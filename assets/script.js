const DROP_AREA_ID = 'drop-area';

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

const handleDrop = (e) => {
    const dt = e.dataTransfer;
    const files = dt.files;
    [...files].forEach(sendFile);
}

const sendFile = async () => {
    let formData = new FormData()
  
    formData.append('file', file)
  
    const res = await fetch(e.target.action, {
        headers: {
            'Content-Type': 'multipart/form-data',
        },
        method: 'POST',
        body: formData
    });
}
