from glob import glob
import os
from flask import jsonify, url_for, abort
from service import app
from service.utils import status

COUNTER = {}

############################################################
# Index page
############################################################
@app.route("/")
def index():
    app.logger.info("Request for Base URL")
    return jsonify(
        status=status.HTTP_200_OK, 
        message="Hit Counter Service", 
        version="1.0.0",
        url=url_for("list_counters", _external=True)
    )

############################################################
# List counters
############################################################
@app.route("/counters", methods=["GET"])
def list_counters():
    app.logger.info("Request to list all counters...")

    counters = [dict(name=count[0], counter=count[1]) for count in COUNTER.items()]

    return jsonify(counters)

############################################################
# Create counters
############################################################
@app.route("/counters/<name>", methods=["POST"])
def create_counters(name):
    app.logger.info("Request to Create counter: %s...", name)
    global COUNTER

    if name in COUNTER:
        return abort(status.HTTP_409_CONFLICT, f"Counter {name} already exists")

    COUNTER[name] = 0

    location_url = url_for('read_counters', name=name, _external=True)
    return jsonify(name=name, counter=0), status.HTTP_201_CREATED, {'Location': location_url}

############################################################
# Read counters
############################################################
@app.route("/counters/<name>", methods=["GET"])
def read_counters(name):
    app.logger.info("Request to Read counter: %s...", name)

    if name not in COUNTER:
        return abort(status.HTTP_404_NOT_FOUND, f"Counter {name} does not exist")

    counter = COUNTER[name]
    return jsonify(name=name, counter=counter)

############################################################
# Update counters
############################################################
@app.route("/counters/<name>", methods=["PUT"])
def update_counters(name):
    app.logger.info("Request to Update counter: %s...", name)
    global COUNTER

    if name not in COUNTER:
        return abort(status.HTTP_404_NOT_FOUND, f"Counter {name} does not exist")

    COUNTER[name] += 1

    counter = COUNTER[name]
    return jsonify(name=name, counter=counter)

############################################################
# Delete counters
############################################################
@app.route("/counters/<name>", methods=["DELETE"])
def delete_counters(name):
    app.logger.info("Request to Delete counter: %s...", name)
    global COUNTER

    if name in COUNTER:
        COUNTER.pop(name)

    return "", status.HTTP_204_NO_CONTENT


############################################################
# Utility for testing
############################################################
def reset_counters():
    """Removes all counters while testing"""
    global COUNTER
    if app.testing:
        COUNTER = {}