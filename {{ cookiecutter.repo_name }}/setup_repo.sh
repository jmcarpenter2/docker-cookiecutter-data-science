#! /bin/bash
curl -H 'Authorization: token {{ cookiecutter.github_API_key }}' https://api.github.com/orgs/{{ cookiecutter.repo_owner }}/repos '{"name":"{{ cookiecutter.repo_name }}","private":true}' || curl -H 'Authorization: token {{ cookiecutter.github_API_key }}' https://api.github.com/user/repos -d '{"name":"{{ cookiecutter.repo_name }}","private":true}'
git init
git add $(pwd)/.
git commit -m "Scaffold repo"
git remote add {{ cookiecutter.repo_name }} git@github.com:{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}.git || git remote add {{ cookiecutter.repo_name }} https://github.com/{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}.git
git push -u {{ cookiecutter.repo_name }} master
curl -u {{ cookiecutter.circleCI_API_key }}: -X POST https://circleci.com/api/v1.1/project/github/{{ cookiecutter.repo_owner }}/{{ cookiecutter.repo_name }}/follow
rm -- "$0"
