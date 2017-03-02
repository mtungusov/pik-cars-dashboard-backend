#!/usr/bin/env bash

export RUN_ENV=development
gradle jrubyJar && java -jar ./build/libs/app-jruby.jar
