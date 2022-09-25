const fastify = require('fastify')()
const Jimp = require('jimp')

const port = 8081
const exportPath = './out/'
const extension = '.png'

let render = {
  imageSize: { x: 0, y: 0 },
  plot: 0,
  pixels: 0
}

const exportImg = (path) => new Promise((resolve, reject) => {
  // eslint-disable-next-line no-new
  new Jimp(render.imageSize.x, render.imageSize.y, function (err, image) {
    if (err) reject(err)

    render.data.forEach((data, i) => image.setPixelColor(data, Math.floor(i / render.imageSize.x), i % render.imageSize.x))

    image.write(path, (err) => {
      if (err) reject(err)
      console.log('SAVED')
      resolve()
    })
  })
})

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
  render.imageSize = request.body.imageSize
  render.pixels = render.imageSize.x * render.imageSize.y
  
  console.log('Started plot', render.plot, ' / ', request.body.allPlots)
  render.data = []
  console.log('Starting render', render.imageSize.x, render.imageSize.y)
  reply.send('ok')
})

fastify.post('/end', async (request, reply) => {
  console.log('Render ended')
  
  const fullExportPath = exportPath + render.plot + extension
  console.log('Storing image in ' + fullExportPath)
  await exportImg(fullExportPath)
  reply.send('ok')
})

fastify.post('/data', (request, reply) => {
  for (let pixel of request.body) render.data.push(Jimp.rgbaToInt(...pixel))
  console.log('GOT PACKETS', request.body.length, '(' + render.data.length + ' / ' + render.pixels + ')')
  reply.send('ok')
})
