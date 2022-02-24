#!/usr/bin/env bash

( cd cart ; bal run &)
( cd currency ; bal run &)
( cd email ; bal run &)
( cd payment ; bal run &)
( cd productcatalog ; bal run &)
( cd recommendation ; bal run &)
( cd shipping ; bal run &)
( cd ads ; bal run &)

sleep 60
( cd checkout ; bal run &)
sleep 60
( cd frontend ; bal run &)
