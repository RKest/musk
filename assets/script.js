// const FORM_ID = 'f';
// const FILE_INP_ID = 'i';

// (function(){
// 	const form = document.getElementById(FORM_ID);
// 	const fileInp = document.getElementById(FILE_INP_ID);
// 	form.addEventListener('submit', async (ev) => {
// 		ev.preventDefault();
// 		const formData = new FormData();
// 		const file = fileInp.files[0];
// 		formData.append('file', file);

// 		const res = await fetch(ev.target.action, {
// 			headers: {
// 				'Content-Type': 'multipart/form-data',
// 			},
// 			method: 'POST',
// 			body: formData
// 		});

// 	})
// })();