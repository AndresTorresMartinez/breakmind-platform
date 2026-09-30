import fastify from 'fastify'

const server = fastify()

server.get('/health', async (request, reply) => {
  return {"status": " :D)"}
})

server.listen({ port: 8080, host: '0.0.0.0' }, (err, address) => {
  if (err) {
    console.error(err)
    process.exit(1)
  }
  console.log(`Server listening at ${address}`)
})