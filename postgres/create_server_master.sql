CREATE TABLE myschema.server_master
(
id BIGSERIAL NOT NULL,
server_id BIGINT,
cpu REAL,
memory BIGINT,
disk TEXT,
"time" BIGINT,
PRIMARY KEY (id)
);
