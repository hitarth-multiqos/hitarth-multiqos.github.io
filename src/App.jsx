import React, { useState, useEffect } from "react";
import "./App.css";

// Read the base URL from environment variables
const BASE_URL = import.meta.env.VITE_PUBLIC_BASEURL;
console.log("BASE_URL", BASE_URL);

function App() {
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [zipUrl, setZipUrl] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [serverStatus, setServerStatus] = useState(false);
  const [previewImages, setPreviewImages] = useState([]);

  const handleFileChange = (e) => {
    setSelectedFiles(e.target.files);
  };

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      alert("Please select at least one file!");
      return;
    }

    setIsProcessing(true);
    setErrorMessage("");

    const formData = new FormData();
    for (let file of selectedFiles) {
      formData.append("images", file);
    }

    try {
      const response = await fetch(`${BASE_URL}/convert`, {
        method: "POST",
        body: formData,
        headers: {
          'ngrok-skip-browser-warning': 'true',  // Skip the warning page
        }
      });

      const data = await response.json();

      if (response.ok) {
        setZipUrl(data.downloadUrl);
        setPreviewImages(data.previewImages || []); // Assuming backend sends preview URLs
      } else {
        setErrorMessage(data.error || "An error occurred during the conversion.");
      }
    } catch (err) {
      setErrorMessage("Error connecting to the API.");
      console.error(err);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDownload = () => {
    if (zipUrl) {
      const link = document.createElement("a");
      link.href = zipUrl;
      link.setAttribute("download", "converted-images.zip");
      document.body.appendChild(link);

      link.click();

      document.body.removeChild(link);
    } else {
      console.log("No data available");
    }
  };

  const checkServerStatus = async () => {
    try {
      const response = await fetch(`${BASE_URL}/`);
      setServerStatus(response.ok);
    } catch (err) {
      setServerStatus(false);
    }
  };

  useEffect(() => {
    const interval = setInterval(checkServerStatus, 5000);
    checkServerStatus();
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="App">
      {/* Centered heading */}
      <h1 className="app-heading">Upload HEIF Images & Convert to JPG</h1>

      {/* Upload files */}
      <input type="file" multiple onChange={handleFileChange} />
      <button onClick={handleUpload} disabled={isProcessing || !serverStatus}>
        {isProcessing ? "Processing..." : "Upload & Convert"}
      </button>

      {/* Download link */}
      {zipUrl && (
        <div>
          <button onClick={handleDownload}>Download Zip</button>
        </div>
      )}

      {/* Error message */}
      {errorMessage && <p className="error">{errorMessage}</p>}

      {/* Preview images */}
      {previewImages.length > 0 && (
        <div className="image-grid">
          {previewImages.map((image, index) => (
            <div key={index} className="image-container">
              <img
                src={`${image}?ngrok-skip-browser-warning=true`}
                alt={`Converted ${index + 1}`}
                className="preview-image"
              />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default App;
