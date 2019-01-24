#! /bin/bash

function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}


# Initial sync of data folder to project specific prefix under the manifold-projects bucket
echo "Creating shared data folders at s3://manifold-projects/{{ cookiecutter.repo_name }}..."
aws s3 sync data s3://manifold-projects/{{ cookiecutter.repo_name }} 
echo "Done."

# Log in to ECR 
echo "Performing docker login to AWS container registry..."
aws ecr get-login --no-include-email | sh
echo "Done."

if [ '{{ cookiecutter.github_API_key }}' != "[OPTIONAL (required for circleCI)] None" ]; then
    echo '{{ cookiecutter.github_API_key }}'
    echo "Registering repo on GitHub..."
    msg=$(curl -H 'Authorization: token {{ cookiecutter.github_API_key }}' https://api.github.com/orgs/{{ cookiecutter.repo_owner }}/repos -d '{"name":"{{ cookiecutter.repo_name }}","private":true}' | jsonValue message)
    if [[ $msg == " Not Found" ]]; then
        curl -H 'Authorization: token {{ cookiecutter.github_API_key }}' https://api.github.com/user/repos -d '{"name":"{{ cookiecutter.repo_name }}","private":true}'
    fi
    echo "Done."

    echo "Making initial commit and pushing to GitHub..."
    git init
    git add $(pwd)/.
    git commit -m "Scaffold repo"

    github_connection="None"
    while [ "$github_connection" != "ssh" ] && [ "$github_connection" != "https" ]
    do
        echo "How do you connect to GitHub? [ssh/https]"
        read github_connection

        if [ "$github_connection" == "ssh" ]; then
            git remote add {{ cookiecutter.repo_name }} git@github.com:{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}.git
        elif [ "$github_connection" == "https" ]; then
            git remote add {{ cookiecutter.repo_name }} https://github.com/{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}.git
        fi

    done
    git push -u {{ cookiecutter.repo_name }} master
    echo "Done."

    if [ '{{ cookiecutter.circleCI_API_key }}' != "[OPTIONAL (required for circleCI)] None" ]; then
        echo "Following the GitHub project on CircleCI..."
        curl -u {{ cookiecutter.circleCI_API_key }}: -X POST https://circleci.com/api/v1.1/project/github/{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}/follow
        echo "Done."
    else
        echo "No circleCI API key provided. Please follow this project on circleCI using the web GUI."
    fi
else
    echo "No GitHub API key provided. Please register this project on GitHub and follow it on circleCI using their respective web GUIs."
fi

echo "All set! Run the start.sh script and open Kitematic from the Docker minibar menu to make sure your container is running the Jupyter service."
