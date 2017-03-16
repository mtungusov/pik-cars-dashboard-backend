#!/usr/bin/env bash

export RUN_ENV=development
#gradle jrubyJar && java -jar ./build/libs/app-jruby.jar
gradle jrubyJar && java -jar ./build/libs/app-jruby.jar -S rackup -p 3000
