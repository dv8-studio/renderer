const fastify = require('fastify')()
const sharp = require('sharp')

const port = 8081
const exportPath = './out/'
const extension = '.png'

let render = {
  imageSize: { x: 0, y: 0 },
  plot: 0,
  nextIndex: 0,
  pixels: 0
}

const exportImg = (path) => {
  const image = sharp(render.data, {
    raw: {
      width: render.imageSize.x,
      height: render.imageSize.y,
      channels: 4
    }
  })
  image.toFile(path)
}

fastify.listen({ port }, (err, address) => {
	if (err) {
		console.error(err);
		process.exit();
	}
	console.log(`Server is now listening on address: ${address}`);
})

fastify.get("/", (request, reply) => reply.send("Running"))

fastify.post('/start', (request, reply) => {
  render.plot = request.body.plot
  render.nextIndex = 0
  render.imageSize = request.body.imageSize
  render.pixels = render.imageSize.x * render.imageSize.y
  
  console.log('Started plot', render.plot, ' / ', request.body.allPlots)
  render.data = new Uint8Array(render.pixels * 4)
  console.log('Starting render', render.imageSize.x, render.imageSize.y)
  reply.send('ok')
})

fastify.post('/end', (request, reply) => {
  console.log('Render ended')
  
  const fullExportPath = exportPath + render.plot + extension
  console.log('Storing image in ' + fullExportPath)
  exportImg(fullExportPath)
  reply.send('ok')
})

fastify.post('/data', (request, reply) => {
  for (let pixelComponent of request.body) render.data[render.nextIndex++] = pixelComponent
  console.log('GOT PACKETS', request.body.length, '(' + ((render.nextIndex - 1) / 4) + ' / ' + render.pixels + ')')
  reply.send('ok')
})
