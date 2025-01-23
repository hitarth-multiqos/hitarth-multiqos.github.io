import React, { useState, useEffect } from "react";
import "./App.css";

// Read the base URL from environment variables
const BASE_URL = import.meta.env.BASEURL;
console.log("BASE_URL", BASE_URL);
function App() {
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [zipUrl, setZipUrl] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [serverStatus, setServerStatus] = useState(false);

  const handleFileChange = e => {
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
        body: formData
      });

      const data = await response.json();

      if (response.ok) {
        setZipUrl(data.downloadUrl);
      } else {
        setErrorMessage(
          data.error || "An error occurred during the conversion."
        );
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
      window.location.href = zipUrl;
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
      <h1>Upload HEIF images & convert to JPG</h1>
      <div
        style={{
          width: "15px",
          height: "15px",
          borderRadius: "50%",
          backgroundColor: serverStatus ? "green" : "red",
          marginBottom: "-2px",
          marginRight: "10px",
          display: "inline-block"
        }}
        title={serverStatus ? "Server is ready" : "Server is down"}
      />
      <input type="file" multiple onChange={handleFileChange} />
      <button onClick={handleUpload} disabled={isProcessing || !serverStatus}>
        {isProcessing ? "Processing..." : "Upload & Convert"}
      </button>

      {zipUrl &&
        <div>
          <button onClick={handleDownload}>Download Zip</button>
        </div>}

      {errorMessage &&
        <p className="error">
          {errorMessage}
        </p>}
    </div>
  );
}

export default App;
