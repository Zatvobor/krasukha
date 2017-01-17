# Krasukha (рус. Красуха)

[![Build Status](https://travis-ci.org/Zatvobor/krasukha.svg?branch=master)](https://travis-ci.org/Zatvobor/krasukha) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Zatvobor/krasukha/blob/master/LICENSE)

## Install distributed node

- `docker build -t krasukha:master .`
- `docker run -p 4369:4369 -dti --name=krasukha krasukha:master`

_It starts an appliance by default (see details in `CMD` statement). Hint: you will be able to overwrite it right over `docker run` command._
