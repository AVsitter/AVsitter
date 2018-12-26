# DUMMY COMMS PROTO

All happens over a single well-known channel `-1252168`

Intentionally no liveness ping / pong check, so bad sim lag or restarts won't cause a dummy to lose its association with furniture.

### DISCOVERY_PING (dummy->furniture): broadcast

Dummy scanning for furniture

* no params

### DISCOVERY_PONG (furniture->dummy): direct
* string friendly_name (Probably llGetObjectName() or root object's name)
* string anims_hash (hash of all anims in inventory created iteratively in
  lexical order like `sha1(anim2 + sha1(anim1)))`. If there is a mismatch
  dummy should remove all existing anims before attempting connect and pass
  a `need_anims` of `TRUE` in its `CONNECT`)

### SOLICIT (furniture->dummy): direct

Furniture asking a dummy to sit down, usually if the
furniture just rezzed the dummy itself. Dummy should follow up
with a `CONNECT` if it wants to sit.

* string anim_hash

### CONNECT (dummy->furniture): direct

Attempt to "sit" on the furniture.

furniture should usually (but not necessarily) return an error if dummy and furniture don't have
the same owner. furniture will normally beam over their anim contents via `llGiveInventory()`,
but that isn't an option if there's an owner mismatch. That shouldn't be a problem if the
owner of the dummy bootstraps its inv contents with whatever anims it might need (bearing in
mind that there may be anim name collisions between different furniture.)

* integer gender (necessary for gendered poses)
* integer need_anims (furniture needs to send anims for us to be able to connect successfully)


### CONNECT_RESP (furniture->dummy): direct

Respond to `CONNECT`, failure if `error` is non-empty.

* string error

### DISCONNECT (dummy<->furniture): direct or broadcast

Tell the other end that we're going away, broadcast via whisper on script
restarts so the other end knows that we're no longer paying attention even
though we no longer have a UUID to tell them directly.

* no params

### SHOW_MENU (dummy->furniture): direct

Ask the furniture's sit script to allow someone to control dummy's menu.
Furniture will not restrict access to this, so the dummy should do its own perms checks
before sending this message.

* key controller

### START_ANIM (furniture->dummy): direct
* string anim_name

### STOP_ANIM (furniture->dummy): direct
* string anim_name

### REPOSITION (furniture->dummy): direct
* vector pos (relative to furniture root)
* rotation rot


## COMMS TODO

* Props? llGiveInventory() + llRezObject() + llCreateLink(), bookkeeping of links?
* RLV pseudo-relay?
* Proxy Xcite stuff?
* More ability for dummies to control furniture programmatically?
* Send anim info to dummies?
