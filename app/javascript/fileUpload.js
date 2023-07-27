import Uppy from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import XHRUpload from '@uppy/xhr-upload';
import AwsS3Multipart from '@uppy/aws-s3-multipart';
import FileInput from '@uppy/file-input';
import Informer from '@uppy/informer';
import ProgressBar from '@uppy/progress-bar';
import ThumbnailGenerator from '@uppy/thumbnail-generator';

const randomstring = require('randomstring')

const singleFileUpload = (fileInput) => {
  const imagePreview = document.getElementById(fileInput.dataset.previewElement)
  const formGroup = fileInput.parentNode

  formGroup.removeChild(fileInput)

  const uppy = fileUpload(fileInput)

  uppy
    .use(FileInput, {
      target: formGroup,
      locale: { strings: { chooseFiles: 'Choose file' } }
    })
    .use(Informer, {
      target: formGroup
    })
    .use(ProgressBar, {
      target: imagePreview.parentNode
    })
    .use(ThumbnailGenerator, {
      thumbnailWidth: 600
    })

  uppy.on('upload-success', (file, response) => {
    const fileData = uploadedFileData(file, response, fileInput)

    // set hidden field value to the uploaded file data so that it's submitted with the form as the attachment
    const hiddenInput = document.getElementById(
      fileInput.dataset.uploadResultElement
    )
    hiddenInput.value = fileData
  })

  uppy.on('thumbnail:generated', (file, preview) => {
    imagePreview.src = preview
  })
}

const multipleFileUpload = (fileInput) => {
  const formGroup = fileInput.parentNode

  const uppy = fileUpload(fileInput)

  uppy.use(Dashboard, {
    target: formGroup,
    inline: true,
    height: 300,
    replaceTargetContent: true
  })

  uppy.on('upload-success', (file, response) => {
    const hiddenField = document.createElement('input')

    hiddenField.type = 'hidden'
    hiddenField.name = `location[file_uploads_attributes][${randomstring.generate()}][image]`
    hiddenField.value = uploadedFileData(file, response, fileInput)

    document.querySelector('form').appendChild(hiddenField)
  })
}

const fileUpload = (fileInput) => {
  const uppy = new Uppy({
    id: fileInput.id,
    autoProceed: true,
    restrictions: {
      allowedFileTypes: fileInput.accept.split(',')
    }
  })

  if (fileInput.dataset.uploadServer == 's3_multipart') {
    uppy.use(AwsS3Multipart, {
      companionUrl: '/' // will call uppy-s3_multipart endpoint mounted on `/s3/multipart`
    })
  } else {
    uppy.use(XHRUpload, {
      endpoint: '/uploads' // Shrine's upload endpoint
    })
  }

  return uppy
}

const uploadedFileData = (file, response, fileInput) => {
  if (fileInput.dataset.uploadServer == 's3_multipart') {
    const id = response.uploadURL.match(/-cache\/([^\?]+)/)[1] // object key without prefix

    return JSON.stringify(fileData(file, id))
  } else {
    return JSON.stringify(response.body)
  }
}

// constructs uploaded file data in the format that Shrine expects
const fileData = (file, id) => ({
  id: id,
  storage: 'cache',
  metadata: {
    size: file.size,
    filename: file.name,
    mime_type: file.type
  }
})

export { singleFileUpload, multipleFileUpload }
