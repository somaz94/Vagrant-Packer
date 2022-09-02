export CEPH_USER="vagrant"
export CEPH_USER_KEY="AQDaIQZi3MAtOxAAMi9nDRP6CXmrn7H69tiKyw=="
export CEPH_POOL="vagrant"
export VIRT_POOL="vagrant-ceph"
export CEPH_RADOS_HOST="192.168.182.201"
export CEPH_RADOS_PORT="6789"
export VIRT_SCRT_UUID="$(uuidgen)"
export VIRT_SCRT_PATH="/tmp/libvirt-secret.xml"
export VIRT_POOL_PATH="/tmp/libvirt-rbd-pool.xml"


cat > "${VIRT_SCRT_PATH}" <<EOF
<secret ephemeral='no' private='no'>
  <uuid>${VIRT_SCRT_UUID}</uuid>
  <usage type='ceph'>
    <name>client.${CEPH_USER} secret</name>
  </usage>
</secret>
EOF

virsh secret-define --file "${VIRT_SCRT_PATH}"
rm -f "${VIRT_SCRT_PATH}"
virsh secret-set-value --secret "${VIRT_SCRT_UUID}" --base64 "${CEPH_USER_KEY}"

cat > "${VIRT_POOL_PATH}" <<EOF
<pool type="rbd">
  <name>${VIRT_POOL}</name>
  <source>
    <name>${CEPH_POOL}</name>
    <host name='${CEPH_RADOS_HOST}' port='${CEPH_RADOS_PORT}' />
    <auth username='${CEPH_USER}' type='ceph'>
      <secret uuid='${VIRT_SCRT_UUID}'/>
    </auth>
  </source>
</pool>
EOF
