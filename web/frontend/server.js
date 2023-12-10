'use strict'

const express = require('express')
const path = require('path')
const app = express()
const { existsSync } = require('fs')

const extensions = ['.ico','.js','.css','.jpg','.png','.map','.ttf','.svg','.csv']

// This code makes sure that any request that does not match a static file
// in the build folder, will just serve index.html. Client side routing is
// going to make sure that the correct content will be loaded.
app.use((req, res, next) => {
    const pp = path.parse(req.path)
    if( extensions.includes(pp.ext) ){
        const filePath = path.join(__dirname,'dist',pp.base)
        if(existsSync(filePath)){
            res.sendFile(filePath)
        }else{
            next()
        }
    } else {
        res.header('Cache-Control', 'private, no-cache, no-store, must-revalidate')
        res.header('Expires','-1')
        res.header('Pragma','no-cache')
        res.sendFile(path.join(__dirname,'dist','index.html'))
    }
})

app.use(express.static(path.join(__dirname, 'dist')))

// Start the server
const PORT = process.env.PORT || 8000
app.listen(PORT, () => {
    console.log(`App listening on port ${PORT}`)
    console.log('Press Ctrl+C to quit.')
})
