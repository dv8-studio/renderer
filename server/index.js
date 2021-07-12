const express = require('express')
const Jimp = require('jimp')

const port = 8081
const exportPath = './out/'
const extension = '.png'

const app = express()

let imageData = []

let xSize = 0
let ySize = 0
let plot = 0
let y = 0

const exportImg = (path) => new Promise((resolve, reject) => {
  // eslint-disable-next-line no-new
  new Jimp(xSize, ySize, function (err, image) {
    if (err) reject(err)

    imageData.forEach((data, i) => image.setPixelColor(data, Math.floor(i / xSize), i % xSize))

    image.write(path, (err) => {
      if (err) reject(err)
      console.log('SAVED')
      resolve()
    })
  })
})

app.post('/requests', express.json({ limit: '10mb' }), async (req, res) => {
  if (req.body[0] === 'RENDER_START') {
    plot = req.body[3]
    console.log('Started plot', plot, ' / ', req.body[4])

    y = 0
    xSize = req.body[1]
    ySize = req.body[2]
    imageData = []
    console.log('Starting render', xSize, ySize)
  } else if (req.body[0] === 'RENDER_END') {
    console.log('Render ended')

    const fullExportPath = exportPath + plot + extension
    console.log('Storing image in ' + fullExportPath)
    await exportImg(fullExportPath)
  } else {
    console.log('GOT PACKETS', req.body.length, '(' + y + ' / ' + xSize * ySize + ')')
    y += req.body.length
    for (let i = 0; i < req.body.length; i++) imageData.push(Jimp.rgbaToInt(...req.body[i]))
  }
  res.send('.')
})
app.get('/requests', (req, res) => res.send('OK'))

app.listen(port, 'localhost', () => { console.log(`Renderer is now listening on "http://localhost:${port}/requests".`) })
