const core = require('@actions/core');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

async function run() {
  try {
    const stepName = core.getInput('step_name', { required: true });
    const command = core.getInput('command', { required: true });

    console.log(`执行步骤: ${stepName}`);
    console.log(`执行命令: ${command}`);

    const { stdout, stderr } = await execAsync(command);
    
    if (stdout) {
      console.log(stdout);
    }
    
    if (stderr) {
      console.error(stderr);
    }

    console.log(`✅ 步骤 '${stepName}' 执行成功`);
  } catch (error) {
    console.error(`❌ 步骤执行失败: ${error.message}`);
    core.setFailed(error.message);
  }
}

run();
