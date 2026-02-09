rm -f lambda_function_payload.zip
rm -rf lambda_package
mkdir lambda_package
pip install -r ac_control_lambda/requirements.txt --target lambda_package
cp ac_control_lambda/src/ac_control_lambda.py lambda_package/ac_control_lambda.py
cd lambda_package
zip -r ../lambda_function_payload.zip *
cd ..
rm -rf lambda_package
