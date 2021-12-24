#!/bin/bash

export SRC_DIR=$(dirname "$0")

bash "$SRC_DIR/letsencrypt-namecheap-dns-auth.sh" production
