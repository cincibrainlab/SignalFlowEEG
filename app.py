from flask import Flask, render_template, request, jsonify
import matlab.engine

app = Flask(__name__)

# Start the MATLAB engine
eng = matlab.engine.start_matlab()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    try:
        # Get the number from the form input
        number = float(request.form['number'])

        # Perform a MATLAB calculation
        result = eng.calculate(number)

        return jsonify({'result': result})
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True)
