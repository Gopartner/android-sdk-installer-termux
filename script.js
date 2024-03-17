function copyCommand() {
  var textToCopy = "npm start";

  navigator.clipboard.writeText(textToCopy)
    .then(() => {
      document.getElementById("copiedText").innerText = "Teks berhasil disalin: " + textToCopy;
    })
    .catch(err => {
      console.error('Gagal menyalin teks: ', err);
    });
}

function copyLink() {
  var linkToCopy = "https://github.com/Gopartner/android-sdk-installer-termux";

  navigator.clipboard.writeText(linkToCopy)
    .then(() => {
      document.getElementById("copiedText").innerText = "Link berhasil disalin: " + linkToCopy;
    })
    .catch(err => {
      console.error('Gagal menyalin link: ', err);
    });
}

