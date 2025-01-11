#!/bin/bash
curl {{ torrent_notify_url }}/refresh-torrent?torrent="$TR_TORRENT_NAME"