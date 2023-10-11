import matlab.engine

# Start MATLAB engine
eng = matlab.engine.start_matlab()

# Define a Python variable that you want to set in MATLAB
python_variable = 42

# Set the MATLAB variable using the Python value
eng.workspace['variable1'] = python_variable

# Access MATLAB workspace variables
variable1 = eng.eval('variable1')  # Replace 'variable1' with the name of your variable

# You can now work with 'variable1' in Python
print(variable1)

# Stop the MATLAB engine when done
eng.quit()
