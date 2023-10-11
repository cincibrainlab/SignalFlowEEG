const express = require('express');
const app = express();
const { spawn } = require('child_process');
const bodyParser = require('body-parser');

// Use bodyParser to parse POST request data
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Serve your HTML and static files
app.use(express.static('public'));

// Start MATLAB as a child process
const matlab = spawn('matlab', ['-nodesktop', '-nosplash', '-wait']);

// Handle MATLAB process events
matlab.stdout.on('data', (data) => {
  console.log(`MATLAB stdout: ${data}`);
});

matlab.stderr.on('data', (data) => {
  console.error(`MATLAB stderr: ${data}`);
});

matlab.on('exit', (code) => {
  console.log(`MATLAB process exited with code ${code}`);
});

// Handle a POST request from your HTML form
app.post('/calculate', (req, res) => {
  const inputData = req.body.inputData; // Assuming you have a form field named "inputData"

    // Send MATLAB command to stdin and listen for the response
    console.log(`Sending MATLAB command: calculate(${inputData})`);
    matlab.write("input(disp('Hello, MATLAB!'))\n");
    matlab.write(`calculate(${inputData})\n`, (error) => {
    if (error) {
        console.error(`Error writing to MATLAB stdin: ${error}`);
        res.status(500).send('Internal Server Error');
        return;
    }
});


  // Listen for the response from MATLAB
  matlab.stdout.once('data', (data) => {
    const result = parseFloat(data.toString().trim()); // Parse the result from MATLAB
    res.send(result.toString()); // Send the result back to the client
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});


