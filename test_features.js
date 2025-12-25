const http = require('http');

function makeRequest(path, method, body) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                resolve({ status: res.statusCode, body: JSON.parse(data || '{}') });
            });
        });

        req.on('error', (e) => reject(e));
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

(async () => {
    try {
        console.log("1. Testing Classification Endpoint...");
        const classification = await makeRequest('/api/classify', 'POST', {
            title: "Schedule urgent meeting with John tomorrow at Starbucks",
            description: "Discuss budget"
        });
        console.log("Result:", JSON.stringify(classification.body, null, 2));

        // console.log("\n2. Testing Manual Override...");
        // const task = await makeRequest('/api/tasks', 'POST', {
        //   title: "Test Override",
        //   category: "finance", // Override
        //   priority: "low"      // Override
        // });
        // console.log("Result:", JSON.stringify(task.body, null, 2));

    } catch (e) {
        console.error(e);
    }
})();
